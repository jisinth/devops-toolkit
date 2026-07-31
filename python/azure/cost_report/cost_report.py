#!/usr/bin/env python3
"""
cost_report.py - Azure Cost Management query for current month cost
grouped by service (ServiceName dimension).

Authenticates via azure-identity's DefaultAzureCredential. The
subscription is taken from --subscription-id, or falls back to the
AZURE_SUBSCRIPTION_ID environment variable.
"""
import argparse
import csv
import json
import os
import sys

from azure.core.exceptions import ClientAuthenticationError, HttpResponseError
from azure.identity import DefaultAzureCredential
from azure.mgmt.costmanagement import CostManagementClient
from azure.mgmt.costmanagement.models import (
    QueryAggregation,
    QueryDataset,
    QueryDefinition,
    QueryGrouping,
    QueryTimePeriod,
)

FIELDNAMES = ["Service", "Amount", "Currency"]


def build_query(timeframe="MonthToDate"):
    """Build a QueryDefinition that sums cost grouped by ServiceName."""
    return QueryDefinition(
        type="ActualCost",
        timeframe=timeframe,
        dataset=QueryDataset(
            granularity="None",
            aggregation={"totalCost": QueryAggregation(name="Cost", function="Sum")},
            grouping=[QueryGrouping(type="Dimension", name="ServiceName")],
        ),
    )


def build_custom_query(start, end):
    """Build a QueryDefinition for an explicit custom date range."""
    query = build_query(timeframe="Custom")
    query.time_period = QueryTimePeriod(from_property=start, to=end)
    return query


def extract_rows(query_result):
    """Flatten a Cost Management query result (rows + column metadata) into dicts."""
    columns = [c.name for c in query_result.columns]
    rows = []
    for raw_row in query_result.rows:
        record = dict(zip(columns, raw_row))
        rows.append(
            {
                "Service": record.get("ServiceName", "Unknown"),
                "Amount": record.get("Cost", record.get("totalCost", 0)),
                "Currency": record.get("Currency", ""),
            }
        )
    rows.sort(key=lambda r: float(r["Amount"] or 0), reverse=True)
    return rows


def collect_costs(cost_client, scope, start=None, end=None):
    query = build_custom_query(start, end) if start and end else build_query()
    result = cost_client.query.usage(scope, query)
    return extract_rows(result)


def print_table(headers, rows):
    if not rows:
        print("No results found.")
        return
    widths = [len(h) for h in headers]
    for row in rows:
        for i, cell in enumerate(row):
            widths[i] = max(widths[i], len(str(cell)))
    fmt = "  ".join(f"{{:<{w}}}" for w in widths)
    print(fmt.format(*headers))
    print(fmt.format(*("-" * w for w in widths)))
    for row in rows:
        print(fmt.format(*(str(c) for c in row)))


def write_json(path, rows):
    with open(path, "w", encoding="utf-8") as f:
        json.dump(rows, f, indent=2, default=str)


def write_csv(path, fieldnames, rows):
    with open(path, "w", encoding="utf-8", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)


def write_outputs(rows, fieldnames, output_paths):
    for path in output_paths or []:
        lower = path.lower()
        if lower.endswith(".json"):
            write_json(path, rows)
            print(f"Wrote {path}")
        elif lower.endswith(".csv"):
            write_csv(path, fieldnames, rows)
            print(f"Wrote {path}")
        else:
            print(
                f"WARNING: unrecognized output extension for '{path}' "
                "(use .json or .csv), skipping",
                file=sys.stderr,
            )


def parse_args(argv=None):
    parser = argparse.ArgumentParser(
        description="Azure Cost Management: cost grouped by service for the current month (or a custom range)."
    )
    parser.add_argument(
        "--subscription-id",
        help="Azure subscription ID. Defaults to the AZURE_SUBSCRIPTION_ID environment variable.",
    )
    parser.add_argument("--start", help="Start date (YYYY-MM-DD). Requires --end. Defaults to month-to-date.")
    parser.add_argument("--end", help="End date (YYYY-MM-DD). Requires --start.")
    parser.add_argument(
        "--output",
        action="append",
        dest="outputs",
        metavar="FILE",
        help="Write results to FILE. Extension (.json or .csv) selects the "
        "format. Repeat to write multiple files.",
    )
    args = parser.parse_args(argv)
    if bool(args.start) != bool(args.end):
        parser.error("--start and --end must be given together")
    return args


def resolve_subscription_id(explicit):
    return explicit or os.environ.get("AZURE_SUBSCRIPTION_ID")


def main(argv=None):
    args = parse_args(argv)

    subscription_id = resolve_subscription_id(args.subscription_id)
    if not subscription_id:
        print(
            "ERROR: No subscription ID given. Pass --subscription-id or set "
            "AZURE_SUBSCRIPTION_ID.",
            file=sys.stderr,
        )
        return 1

    scope = f"/subscriptions/{subscription_id}"

    try:
        credential = DefaultAzureCredential()
        client = CostManagementClient(credential)
        rows = collect_costs(client, scope, start=args.start, end=args.end)
    except ClientAuthenticationError as e:
        print(
            f"ERROR: Azure authentication failed: {e}. Run `az login`, or "
            "configure a service principal / managed identity.",
            file=sys.stderr,
        )
        return 1
    except HttpResponseError as e:
        print(f"ERROR: Azure API error: {e.message if hasattr(e, 'message') else e}", file=sys.stderr)
        return 1

    label = f"{args.start} to {args.end}" if args.start else "month-to-date"
    print(f"Cost by service, {label}:")
    rows_as_lists = [[r[f] for f in FIELDNAMES] for r in rows]
    print_table(FIELDNAMES, rows_as_lists)
    write_outputs(rows, FIELDNAMES, args.outputs)
    return 0


if __name__ == "__main__":
    sys.exit(main())
