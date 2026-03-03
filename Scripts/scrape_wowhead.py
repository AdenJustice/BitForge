"""
Scrape not-disenchantable item IDs from Wowhead using Playwright.
URL: https://www.wowhead.com/items/armor/quality:2:3:4?filter=8;2;0

Wowhead renders item data via JavaScript (Listview), so Playwright is used
to execute the page and extract IDs directly from the live DOM via JS.

Install dependencies:
    pip install playwright
    playwright install chromium
"""

import argparse
import time
from pathlib import Path

from playwright.sync_api import Page, sync_playwright

# ── Configuration ─────────────────────────────────────────────────────────────

DEFAULT_DELAY = 1  # seconds between page requests
BASE_URL = "https://www.wowhead.com/items/armor/quality:2:3:4?filter=8;2;0"  # armor
ITEMS_PER_PAGE = 50

LUA_TABLE_NAME = "nonDisenchantableItemIDs"
LUA_OUTPUT_FILE = "not_disenchantable_item_ids.lua"
DELETE_INTERMEDIATE_TEXT_FILES = True

# Configure all target URLs here (including per-URL total override if needed).
SCRAPE_TARGETS = [
    {
        "name": "armor",
        "url": "https://www.wowhead.com/items/armor/quality:2:3:4?filter=8;2;0",
        "total": 1041,
    },
    {
        "name": "weapons",
        "url": "https://www.wowhead.com/items/weapons/quality:2:3:4?filter=8;2;0",
        "total": 1002,
    },
]

# JavaScript that runs inside the browser to extract item IDs from the DOM.
# Reads hrefs from listview-row anchor tags, e.g. /item=12345/foo -> 12345
EXTRACT_IDS_JS = """
() => {
    const ids = [];
    document.querySelectorAll('tr.listview-row td a[href*="/item="]').forEach(a => {
        const m = a.href.match(/\\/item=(\\d+)/);
        if (m) ids.push(parseInt(m[1], 10));
    });
    return [...new Set(ids)];
}
"""

# JavaScript to read the total item count from Wowhead's inline Listview config
EXTRACT_TOTAL_JS = """
() => {
    // Wowhead stores Listview instances in window.g_listviews or similar;
    // most reliable: scan all inline <script> text for the Listview({...total:N...}) call
    const scripts = Array.from(document.querySelectorAll('script'));
    for (const s of scripts) {
        const t = s.textContent;
        // Match: new Listview({...  "total":12345  ...})
        const m = t.match(/new Listview\\s*\\([\\s\\S]*?"total"\\s*:\\s*(\\d+)/);
        if (m) return parseInt(m[1], 10);
    }
    // Last resort: any "total":N in any script
    for (const s of scripts) {
        const m = s.textContent.match(/"total"\\s*:\\s*(\\d+)/);
        if (m) return parseInt(m[1], 10);
    }
    return 0;
}
"""


# JavaScript to click Wowhead's "Next Page" button
FIND_NEXT_JS = """
() => {
    const nav = document.querySelector('.listview-nav');
    if (!nav) return null;
    const links = Array.from(nav.querySelectorAll('a'));
    for (let i = links.length - 1; i >= 0; i--) {
        const a = links[i];
        if (!a.classList.contains('listview-nav-disabled')) {
            // Return a unique selector we can use to click it
            return '.listview-nav a:not(.listview-nav-disabled):last-of-type';
        }
    }
    return null;
}
"""

# JavaScript to get current page number from Wowhead's listview nav
GET_PAGE_NUM_JS = """
() => {
    const active = document.querySelector('.listview-nav .listview-nav-page-current, .listview-nav b');
    return active ? parseInt(active.textContent.trim(), 10) : null;
}
"""


# ── Playwright fetching ────────────────────────────────────────────────────────


def wait_for_rows(page: Page, timeout_ms: int = 30_000):
    """Wait for listview rows to be present in DOM."""
    try:
        page.wait_for_selector("tr.listview-row", timeout=timeout_ms)
    except Exception:
        print("  Warning: listview-row selector timed out.")
    page.wait_for_timeout(1_000)


def extract_ids(page: Page) -> list[int]:
    """Extract item IDs from current page via JS."""
    return page.evaluate(EXTRACT_IDS_JS)


def fetch_first_page(page: Page) -> tuple[list[int], int]:
    """Load the first page and return (ids, total)."""
    page.goto(BASE_URL, wait_until="domcontentloaded", timeout=60_000)
    wait_for_rows(page)
    ids = extract_ids(page)
    total = page.evaluate(EXTRACT_TOTAL_JS)
    return ids, total


def fetch_next_page(page: Page, expected_page_num: int) -> list[int]:
    """Click next page, wait for new rows, return IDs."""
    current_ids = page.evaluate(EXTRACT_IDS_JS)
    first_id = current_ids[0] if current_ids else None

    # Click the "Next ›" link specifically
    try:
        next_btn = page.locator(
            '.listview-nav a.listview-nav-link[data-visible="true"]', has_text="Next"
        )
        if next_btn.count() == 0:
            print("  Warning: Next button not found or disabled.")
            return []
        next_btn.first.click()
    except Exception as e:
        print(f"  Warning: click failed: {e}")
        return []

    # Wait until the first visible item ID changes
    deadline = 20_000  # ms
    interval = 500
    elapsed = 0
    while elapsed < deadline:
        page.wait_for_timeout(interval)
        elapsed += interval
        new_ids = page.evaluate(EXTRACT_IDS_JS)
        if new_ids and new_ids[0] != first_id:
            return new_ids

    print(
        f"  Warning: page did not change after clicking next (still starts with id {first_id})."
    )
    return page.evaluate(EXTRACT_IDS_JS)


# ── Main scraper ───────────────────────────────────────────────────────────────


def scrape_all_item_ids(
    delay: float = DEFAULT_DELAY,
    headless: bool = True,
    output_file: str = "not_disenchantable_item_ids.txt",
    total_override: int = 0,
) -> list[int]:
    all_ids: list[int] = []

    with sync_playwright() as pw:
        browser = pw.chromium.launch(headless=headless)
        context = browser.new_context(
            user_agent=(
                "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
                "AppleWebKit/537.36 (KHTML, like Gecko) "
                "Chrome/122.0.0.0 Safari/537.36"
            ),
            locale="en-US",
        )
        page = context.new_page()

        def flush(ids: list[int]):
            """Write current deduplicated sorted IDs to file."""
            sorted_ids = sorted(set(ids))
            with open(output_file, "w") as f:
                for item_id in sorted_ids:
                    f.write(f"{item_id}\n")

        # ── Page 1 ──
        print("Fetching page 1 ...")
        ids, detected_total = fetch_first_page(page)
        total = total_override or detected_total
        print(
            f"Total items: {total or 'unknown'}{' (manual)' if total_override else ''}"
        )
        all_ids.extend(ids)
        flush(all_ids)
        print(f"  Page 1: {len(ids)} item IDs collected")

        # ── Subsequent pages (click-based navigation) ──
        if total and total > ITEMS_PER_PAGE:
            num_pages = (total + ITEMS_PER_PAGE - 1) // ITEMS_PER_PAGE
            for page_num in range(2, num_pages + 1):
                time.sleep(delay)
                print(f"Fetching page {page_num} of {num_pages} ...")
                ids = fetch_next_page(page, page_num)
                if not ids:
                    print("  No items found -- stopping early.")
                    break
                all_ids.extend(ids)
                flush(all_ids)
                print(
                    f"  Page {page_num}: {len(ids)} item IDs collected (total unique so far: {len(set(all_ids))})"
                )

        browser.close()

    # Deduplicate and sort
    all_ids = sorted(set(all_ids))

    print(f"\nTotal unique item IDs scraped: {len(all_ids)}")
    with open(output_file, "w") as f:
        for item_id in all_ids:
            f.write(f"{item_id}\n")
    print(f"Saved to: {output_file}")
    print("First 20 IDs:", all_ids[:20])

    return all_ids


def to_lua(ids: list[int], table_name: str) -> str:
    lines = [f"{table_name} = {{"]
    lines.extend(f'    ["{item_id}"] = true,' for item_id in ids)
    lines.append("}")
    return "\n".join(lines) + "\n"


def run_configured_scrapes(
    delay: float,
    headless: bool,
    lua_output_file: str,
) -> list[int]:
    merged_ids: list[int] = []
    seen: set[int] = set()
    intermediate_files: list[Path] = []

    for target in SCRAPE_TARGETS:
        global BASE_URL
        BASE_URL = target["url"]
        total_override = int(target.get("total", 0) or 0)
        temp_output = f"{target['name']}_ids.txt"
        intermediate_files.append(Path(temp_output))

        print(f"\n=== Scraping {target['name']} ===")
        ids = scrape_all_item_ids(
            delay=delay,
            headless=headless,
            output_file=temp_output,
            total_override=total_override,
        )

        for item_id in ids:
            if item_id not in seen:
                seen.add(item_id)
                merged_ids.append(item_id)

    merged_ids = sorted(merged_ids)
    lua_text = to_lua(merged_ids, LUA_TABLE_NAME)
    with open(lua_output_file, "w") as f:
        f.write(lua_text)

    if DELETE_INTERMEDIATE_TEXT_FILES:
        for temp_file in intermediate_files:
            temp_file.unlink(missing_ok=True)

    print(f"\nMerged unique item IDs: {len(merged_ids)}")
    print(f"Lua table name: {LUA_TABLE_NAME}")
    print(f"Saved Lua table to: {lua_output_file}")
    return merged_ids


# ── CLI ────────────────────────────────────────────────────────────────────────


def main():
    parser = argparse.ArgumentParser(
        description="Scrape not-disenchantable item IDs from Wowhead."
    )
    parser.add_argument(
        "--delay",
        type=float,
        default=DEFAULT_DELAY,
        help="Seconds to wait between page requests (default: DEFAULT_DELAY)",
    )
    parser.add_argument(
        "--no-headless",
        action="store_true",
        help="Show the browser window while scraping",
    )
    parser.add_argument(
        "--output",
        type=str,
        default="not_disenchantable_item_ids.txt",
        help="Output path for single-url mode (default: not_disenchantable_item_ids.txt)",
    )
    parser.add_argument(
        "--total",
        type=int,
        default=0,
        help="Total number of items for single-url mode (overrides auto-detection)",
    )
    parser.add_argument(
        "--single-url",
        action="store_true",
        help="Run single-url mode using BASE_URL instead of SCRAPE_TARGETS",
    )
    parser.add_argument(
        "--lua-output",
        type=str,
        default=LUA_OUTPUT_FILE,
        help=f"Lua output path for configured mode (default: {LUA_OUTPUT_FILE})",
    )
    args = parser.parse_args()

    if args.single_url:
        scrape_all_item_ids(
            delay=args.delay,
            headless=not args.no_headless,
            output_file=args.output,
            total_override=args.total,
        )
        return

    run_configured_scrapes(
        delay=args.delay,
        headless=not args.no_headless,
        lua_output_file=args.lua_output,
    )


if __name__ == "__main__":
    main()
