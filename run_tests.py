import sys
import os
import argparse
import subprocess
from datetime import datetime

def main():
    parser = argparse.ArgumentParser(description="HealthGuard AI Test Framework Runner")
    parser.add_argument("--all", action="store_true", help="Run full test suite (Web, Mobile, API, Performance)")
    parser.add_argument("--web", action="store_true", help="Run Selenium Web UI tests")
    parser.add_argument("--mobile", action="store_true", help="Run Appium Mobile tests")
    parser.add_argument("--api", action="store_true", help="Run REST API tests")
    parser.add_argument("--performance", action="store_true", help="Run Performance benchmark & load tests")
    parser.add_argument("--smoke", action="store_true", help="Run Smoke test suite")
    parser.add_argument("--regression", action="store_true", help="Run Regression test suite")
    parser.add_argument("--headless", action="store_true", default=True, help="Run browser in headless mode")
    parser.add_argument("--parallel", type=int, default=0, help="Number of parallel processes (e.g. --parallel 4)")
    parser.add_argument("--collect-only", action="store_true", help="Collect and count total test cases")

    args = parser.parse_args()

    cmd = [sys.executable, "-m", "pytest"]

    if args.collect_only:
        cmd.append("--collect-only")
        res = subprocess.run(cmd)
        sys.exit(res.returncode)

    marks = []
    if args.web:
        marks.append("web")
    if args.mobile:
        marks.append("mobile")
    if args.api:
        marks.append("api")
    if args.performance:
        marks.append("performance")
    if args.smoke:
        marks.append("smoke")
    if args.regression:
        marks.append("regression")

    if marks and not args.all:
        cmd.extend(["-m", " or ".join(marks)])

    if args.parallel > 1:
        cmd.extend(["-n", str(args.parallel)])

    os.makedirs("tests/reports", exist_ok=True)
    report_html = "tests/reports/report.html"
    report_xml = "tests/reports/junit.xml"
    cmd.extend([
        f"--html={report_html}",
        "--self-contained-html",
        f"--junitxml={report_xml}"
    ])

    print("=" * 70)
    print("HEALTHGUARD AI AUTOMATED TEST SUITE RUNNER")
    print(f"   Timestamp: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"   Command: {' '.join(cmd)}")
    print("=" * 70)

    start_time = datetime.now()
    result = subprocess.run(cmd)
    duration = (datetime.now() - start_time).total_seconds()

    print("\n" + "=" * 70)
    print("TEST EXECUTION SUMMARY")
    print("=" * 70)
    print(f"  Duration    : {duration:.2f} seconds")
    print(f"  HTML Report : file:///{os.path.abspath(report_html).replace('\\', '/')}")
    print(f"  JUnit XML   : file:///{os.path.abspath(report_xml).replace('\\', '/')}")
    print(f"  Exit Status : {'PASSED (0)' if result.returncode == 0 else f'FAILED ({result.returncode})'}")
    print("=" * 70)

    sys.exit(result.returncode)

if __name__ == "__main__":
    main()
