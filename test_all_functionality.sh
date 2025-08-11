#!/bin/bash

# UC-1 Pro Operations Center - Comprehensive Functionality Test
# This script tests all critical backend APIs and frontend routes

echo "🔍 UC-1 Pro Operations Center - Full System Test"
echo "=================================================="

BASE_URL="http://localhost:8084"
FAILED_TESTS=0
TOTAL_TESTS=0

# Test function
test_endpoint() {
    local name="$1"
    local url="$2"
    local method="${3:-GET}"
    local expected_code="${4:-200}"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    echo -n "Testing $name... "
    
    if [ "$method" = "GET" ]; then
        response=$(curl -s -w "%{http_code}" "$BASE_URL$url")
    else
        response=$(curl -s -w "%{http_code}" -X "$method" "$BASE_URL$url")
    fi
    
    http_code="${response: -3}"
    
    if [ "$http_code" = "$expected_code" ]; then
        echo "✅ PASS ($http_code)"
    else
        echo "❌ FAIL ($http_code, expected $expected_code)"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
}

echo
echo "📊 Testing Core API Endpoints"
echo "-----------------------------"
test_endpoint "System Status" "/api/v1/system/status"
test_endpoint "System Hardware" "/api/v1/system/hardware"
test_endpoint "System Disk I/O" "/api/v1/system/disk-io"
test_endpoint "Services List" "/api/v1/services"
test_endpoint "Models List" "/api/v1/models"
test_endpoint "Models Settings" "/api/v1/models/settings"

echo
echo "🌐 Testing Frontend Routes"
echo "-------------------------"
test_endpoint "Public Landing Page" "/"
test_endpoint "Admin Dashboard" "/admin/"
test_endpoint "Models Management" "/admin/models"
test_endpoint "Services Page" "/admin/services"
test_endpoint "System Monitoring" "/admin/system"
test_endpoint "Network Config" "/admin/network"
test_endpoint "Storage & Backup" "/admin/storage"
test_endpoint "Logs Viewer" "/admin/logs"
test_endpoint "Security Settings" "/admin/security"
test_endpoint "Extensions Manager" "/admin/extensions"
test_endpoint "Settings Page" "/admin/settings"

echo
echo "📋 Testing API Documentation"
echo "---------------------------"
test_endpoint "Swagger UI" "/docs"
test_endpoint "OpenAPI Spec" "/openapi.json"

echo
echo "🔧 Testing Special Endpoints"
echo "---------------------------"
test_endpoint "WebSocket Connection" "/ws" "GET" "426"  # Upgrade Required is expected
test_endpoint "Favicon" "/favicon.ico" "GET" "200"

echo
echo "📈 Results Summary"
echo "=================="
PASSED_TESTS=$((TOTAL_TESTS - FAILED_TESTS))
echo "Total Tests: $TOTAL_TESTS"
echo "Passed: $PASSED_TESTS"
echo "Failed: $FAILED_TESTS"

if [ $FAILED_TESTS -eq 0 ]; then
    echo "🎉 ALL TESTS PASSED! System is fully functional."
    exit 0
else
    echo "⚠️  Some tests failed. Check the issues above."
    exit 1
fi