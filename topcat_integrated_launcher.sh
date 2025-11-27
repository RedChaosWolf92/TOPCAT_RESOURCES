#!/bin/bash
#
# TOPCAT Smart Launcher with Integrated Diagnostics
# This replaces /usr/local/bin/topcat with user-friendly error handling
#
# Installation:
#   sudo cp this_file /usr/local/bin/topcat
#   sudo chmod +x /usr/local/bin/topcat
#
# Usage:
#   topcat              - Launch TOPCAT (auto-diagnoses if fails)
#   topcat --doctor     - Run diagnostics only
#   topcat --help       - Show help
#   topcat file.fits    - Open file in TOPCAT
#

# Color codes for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Error codes
declare -A ERROR_CODES=(
    [001]="Display not configured"
    [002]="X server not running"
    [003]="X authorization missing"
    [004]="Java GUI libraries missing"
    [005]="TOPCAT not installed"
    [006]="X11 display inaccessible"
    [007]="Java version inadequate"
)

declare -A ERROR_FIXES=(
    [001]="export DISPLAY=:0 && echo 'export DISPLAY=:0' >> ~/.zshrc"
    [002]="sudo apt install xwayland && logout/login"
    [003]="xhost +local: OR export XAUTHORITY=\$(ls /run/user/1000/.mutter-Xwaylandauth* | head -1)"
    [004]="sudo apt remove openjdk-*-jre-headless && sudo apt install openjdk-21-jdk openjdk-21-jre"
    [005]="Download from https://www.star.bris.ac.uk/~mbt/topcat/ and move to /opt/topcat/"
    [006]="Check that X server is running: ps aux | grep -i xwayland"
    [007]="sudo apt install openjdk-21-jdk"
)

#==============================================================================
# DIAGNOSTIC FUNCTIONS
#==============================================================================

run_diagnostics() {
    local auto_mode=$1  # If true, only show failures
    local failed_checks=()
    local total_checks=0
    local passed_checks=0
    
    if [ "$auto_mode" != "true" ]; then
        echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${BLUE}🔬 TOPCAT Doctor - Running Diagnostics${NC}"
        echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
    fi
    
    # Check 1: DISPLAY variable
    total_checks=$((total_checks + 1))
    if [ -n "$DISPLAY" ]; then
        [ "$auto_mode" != "true" ] && echo -e "[$total_checks] DISPLAY variable... ${GREEN}✅ PASS${NC} ($DISPLAY)"
        passed_checks=$((passed_checks + 1))
    else
        [ "$auto_mode" != "true" ] && echo -e "[$total_checks] DISPLAY variable... ${RED}❌ FAIL${NC}"
        failed_checks+=(001)
    fi
    
    # Check 2: XWayland running
    total_checks=$((total_checks + 1))
    if ps aux | grep -i xwayland | grep -q -v grep; then
        [ "$auto_mode" != "true" ] && echo -e "[$total_checks] XWayland running... ${GREEN}✅ PASS${NC}"
        passed_checks=$((passed_checks + 1))
    else
        [ "$auto_mode" != "true" ] && echo -e "[$total_checks] XWayland running... ${RED}❌ FAIL${NC}"
        failed_checks+=(002)
    fi
    
    # Check 3: XAUTHORITY
    total_checks=$((total_checks + 1))
    if [ -n "$XAUTHORITY" ] && [ -f "$XAUTHORITY" ]; then
        [ "$auto_mode" != "true" ] && echo -e "[$total_checks] XAUTHORITY file... ${GREEN}✅ PASS${NC}"
        passed_checks=$((passed_checks + 1))
    else
        # Check if xhost is allowing local connections (alternative to XAUTHORITY)
        if xhost 2>/dev/null | grep -q "LOCAL"; then
            [ "$auto_mode" != "true" ] && echo -e "[$total_checks] XAUTHORITY file... ${GREEN}✅ PASS${NC} (xhost allows local)"
            passed_checks=$((passed_checks + 1))
        else
            [ "$auto_mode" != "true" ] && echo -e "[$total_checks] XAUTHORITY file... ${YELLOW}⚠️  WARNING${NC}"
            failed_checks+=(003)
        fi
    fi
    
    # Check 4: Java GUI libraries
    total_checks=$((total_checks + 1))
    if ls /usr/lib/jvm/java-*/lib/libawt_xawt.so > /dev/null 2>&1; then
        [ "$auto_mode" != "true" ] && echo -e "[$total_checks] Java GUI libraries... ${GREEN}✅ PASS${NC}"
        passed_checks=$((passed_checks + 1))
    else
        [ "$auto_mode" != "true" ] && echo -e "[$total_checks] Java GUI libraries... ${RED}❌ FAIL${NC}"
        failed_checks+=(004)
    fi
    
    # Check 5: TOPCAT installed
    total_checks=$((total_checks + 1))
    if [ -f /opt/topcat/topcat-full.jar ]; then
        [ "$auto_mode" != "true" ] && echo -e "[$total_checks] TOPCAT installed... ${GREEN}✅ PASS${NC}"
        passed_checks=$((passed_checks + 1))
    else
        [ "$auto_mode" != "true" ] && echo -e "[$total_checks] TOPCAT installed... ${RED}❌ FAIL${NC}"
        failed_checks+=(005)
    fi
    
    # Check 6: X11 display accessible
    total_checks=$((total_checks + 1))
    if DISPLAY=${DISPLAY:-:0} xdpyinfo > /dev/null 2>&1; then
        [ "$auto_mode" != "true" ] && echo -e "[$total_checks] X11 display accessible... ${GREEN}✅ PASS${NC}"
        passed_checks=$((passed_checks + 1))
    else
        [ "$auto_mode" != "true" ] && echo -e "[$total_checks] X11 display accessible... ${RED}❌ FAIL${NC}"
        failed_checks+=(006)
    fi
    
    # Check 7: Java version
    total_checks=$((total_checks + 1))
    if java -version 2>&1 | grep -q 'version "[12][0-9]'; then
        java_ver=$(java -version 2>&1 | head -1 | cut -d'"' -f2)
        [ "$auto_mode" != "true" ] && echo -e "[$total_checks] Java version... ${GREEN}✅ PASS${NC} ($java_ver)"
        passed_checks=$((passed_checks + 1))
    else
        [ "$auto_mode" != "true" ] && echo -e "[$total_checks] Java version... ${RED}❌ FAIL${NC}"
        failed_checks+=(007)
    fi
    
    # Summary
    if [ "$auto_mode" != "true" ]; then
        echo ""
        echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "📊 Results: ${GREEN}$passed_checks${NC}/${total_checks} checks passed"
        echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
    fi
    
    # Return failed checks
    if [ ${#failed_checks[@]} -gt 0 ]; then
        if [ "$auto_mode" == "true" ]; then
            # Auto mode: show concise error report
            echo ""
            echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            echo -e "${RED}❌ TOPCAT cannot start - Configuration issues detected${NC}"
            echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            echo ""
        fi
        
        for code in "${failed_checks[@]}"; do
            echo -e "${RED}ERROR TOPCAT-$code:${NC} ${ERROR_CODES[$code]}"
            echo -e "${YELLOW}FIX:${NC} ${ERROR_FIXES[$code]}"
            echo ""
        done
        
        if [ "$auto_mode" == "true" ]; then
            echo -e "${BLUE}💡 Run 'topcat --doctor' for full diagnostic report${NC}"
            echo ""
        else
            echo -e "${RED}❌ Fix the issues above, then try 'topcat' again${NC}"
        fi
        
        return 1
    else
        if [ "$auto_mode" != "true" ]; then
            echo -e "${GREEN}✅ All checks passed! TOPCAT should work.${NC}"
            echo -e "${GREEN}   Run: topcat${NC}"
        fi
        return 0
    fi
}

#==============================================================================
# ERROR TRANSLATION FUNCTION
#==============================================================================

translate_java_error() {
    local error_output="$1"
    
    if echo "$error_output" | grep -q "java.awt.HeadlessException"; then
        echo -e "${RED}ERROR TOPCAT-001:${NC} ${ERROR_CODES[001]}"
        echo -e "${YELLOW}FIX:${NC} ${ERROR_FIXES[001]}"
        return 001
    elif echo "$error_output" | grep -q "UnsatisfiedLinkError.*libawt_xawt"; then
        echo -e "${RED}ERROR TOPCAT-004:${NC} ${ERROR_CODES[004]}"
        echo -e "${YELLOW}FIX:${NC} ${ERROR_FIXES[004]}"
        return 004
    elif echo "$error_output" | grep -q "Authorization required"; then
        echo -e "${RED}ERROR TOPCAT-003:${NC} ${ERROR_CODES[003]}"
        echo -e "${YELLOW}FIX:${NC} ${ERROR_FIXES[003]}"
        return 003
    elif echo "$error_output" | grep -q "Can't connect to X11"; then
        echo -e "${RED}ERROR TOPCAT-006:${NC} ${ERROR_CODES[006]}"
        echo -e "${YELLOW}FIX:${NC} ${ERROR_FIXES[006]}"
        return 006
    fi
    
    return 0
}

#==============================================================================
# HELP FUNCTION
#==============================================================================

show_help() {
    echo "TOPCAT Smart Launcher"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Usage:"
    echo "  topcat                 Launch TOPCAT"
    echo "  topcat file.fits       Open file in TOPCAT"
    echo "  topcat --doctor        Run diagnostics only"
    echo "  topcat --help          Show this help"
    echo ""
    echo "Features:"
    echo "  • Automatic error detection and diagnosis"
    echo "  • User-friendly error messages with fixes"
    echo "  • Pre-flight checks before launching"
    echo ""
    echo "Error Codes:"
    for code in $(echo ${!ERROR_CODES[@]} | tr ' ' '\n' | sort); do
        echo "  TOPCAT-$code: ${ERROR_CODES[$code]}"
    done
    echo ""
    echo "For detailed troubleshooting:"
    echo "  ~/astronomy-dev/TOPCAT_TROUBLESHOOTING.md"
    echo ""
}

#==============================================================================
# MAIN LOGIC
#==============================================================================

# Parse arguments
case "$1" in
    --doctor)
        run_diagnostics false
        exit $?
        ;;
    --help|-h)
        show_help
        exit 0
        ;;
    --version)
        echo "TOPCAT Smart Launcher v1.0"
        java -jar /opt/topcat/topcat-full.jar --version 2>/dev/null || echo "TOPCAT not found"
        exit 0
        ;;
esac

# Pre-flight checks (silent mode - only shows failures)
if ! run_diagnostics true; then
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}💡 TIP: After fixing issues, run 'topcat --doctor' to verify${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    exit 1
fi

# All checks passed, launch TOPCAT
echo -e "${GREEN}✅ Pre-flight checks passed - launching TOPCAT...${NC}"
echo ""

# Capture errors
error_log=$(mktemp)
java -Djava.awt.headless=false -jar /opt/topcat/topcat-full.jar "$@" 2>&1 | tee "$error_log" &
java_pid=$!

# Wait a moment to see if it crashes immediately
sleep 2

if ! ps -p $java_pid > /dev/null 2>&1; then
    # Java process died, analyze the error
    echo ""
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${RED}❌ TOPCAT failed to start${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    # Translate error
    translate_java_error "$(cat "$error_log")"
    
    echo ""
    echo -e "${BLUE}💡 Run 'topcat --doctor' for full diagnostics${NC}"
    
    rm -f "$error_log"
    exit 1
else
    # TOPCAT is running
    rm -f "$error_log"
    wait $java_pid
    exit $?
fi
