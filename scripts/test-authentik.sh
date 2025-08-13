#!/bin/bash

# UC-1 Pro Authentik Test Script
# This script tests the Authentik SSO integration

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}🔐 Testing Authentik SSO Integration...${NC}"
echo

# Test 1: Check if Authentik containers are running
echo -e "${YELLOW}Test 1: Container Status${NC}"
if docker ps --format "table {{.Names}}\t{{.Status}}" | grep -E "(authentik-server|authentik-postgresql|authentik-redis|authentik-worker)" | grep -q "Up"; then
    echo -e "${GREEN}✅ Authentik containers are running${NC}"
    docker ps --format "table {{.Names}}\t{{.Status}}" | grep authentik
else
    echo -e "${RED}❌ Authentik containers not running${NC}"
    echo "Run: make authentik-start"
    exit 1
fi
echo

# Test 2: Check Authentik health endpoint
echo -e "${YELLOW}Test 2: Health Check${NC}"
if curl -s -f http://localhost:9005/-/health/live/ > /dev/null; then
    echo -e "${GREEN}✅ Authentik health endpoint responding${NC}"
else
    echo -e "${RED}❌ Authentik health endpoint not responding${NC}"
    echo "Check logs: make authentik-logs"
fi
echo

# Test 3: Check database connection
echo -e "${YELLOW}Test 3: Database Connection${NC}"
if docker exec authentik-server ak check_db 2>/dev/null | grep -q "Database connectivity: OK"; then
    echo -e "${GREEN}✅ Database connection working${NC}"
else
    echo -e "${RED}❌ Database connection failed${NC}"
    echo "Check PostgreSQL logs: docker logs authentik-postgresql"
fi
echo

# Test 4: Check Redis connection
echo -e "${YELLOW}Test 4: Redis Connection${NC}"
if docker exec authentik-redis redis-cli ping 2>/dev/null | grep -q "PONG"; then
    echo -e "${GREEN}✅ Redis connection working${NC}"
else
    echo -e "${RED}❌ Redis connection failed${NC}"
    echo "Check Redis logs: docker logs authentik-redis"
fi
echo

# Test 5: Check admin interface accessibility
echo -e "${YELLOW}Test 5: Admin Interface${NC}"
if curl -s http://localhost:9005/if/admin/ | grep -q "authentik"; then
    echo -e "${GREEN}✅ Admin interface accessible${NC}"
    echo -e "   Admin URL: ${BLUE}http://localhost:9005/if/admin/${NC}"
else
    echo -e "${RED}❌ Admin interface not accessible${NC}"
fi
echo

# Test 6: Check API endpoint
echo -e "${YELLOW}Test 6: API Endpoint${NC}"
if curl -s http://localhost:9005/api/v3/ | grep -q '"version"'; then
    echo -e "${GREEN}✅ API endpoint responding${NC}"
    echo -e "   API URL: ${BLUE}http://localhost:9005/api/v3/${NC}"
else
    echo -e "${RED}❌ API endpoint not responding${NC}"
fi
echo

# Summary
echo -e "${BLUE}📋 Quick Start Summary:${NC}"
echo -e "   1. Admin Interface: ${GREEN}http://localhost:9005${NC}"
echo -e "   2. Default Login:"
echo -e "      Email:    ${GREEN}admin@magicunicorn.tech${NC}"
echo -e "      Password: ${GREEN}MagicUnicorn!Auth${NC}"
echo -e "   3. ${RED}Change password immediately!${NC}"
echo
echo -e "${YELLOW}📚 Next Steps:${NC}"
echo -e "   • Configure Microsoft 365: Add Azure AD application"
echo -e "   • Configure Google Workspace: Add OAuth2 credentials"
echo -e "   • Set up LDAP: Configure directory connection"
echo -e "   • Create users and groups"
echo
echo -e "${GREEN}🎉 Authentik SSO is ready for configuration! 🦄${NC}"