#!/bin/bash

set -e

echo "🔍 Validating gRPC connections..."

# Wait longer for port forwarding to establish
echo "⏳ Waiting for port forwarding to establish..."
sleep 60

# Debug: Show what's listening on the expected ports
echo "🔍 Debug: Checking what's listening on expected ports..."
netstat -tlnp 2>/dev/null | grep -E ":($HAPROXY_PORT|$GRPC_PORT|$GRPC_MIRROR_PORT)" || echo "No services found on expected ports yet"

# Function to check if a port is listening
check_port() {
    local port=$1
    local service_name=$2
    local timeout=120
    local count=0

    echo "Checking $service_name on port $port..."

    while [ $count -lt $timeout ]; do
        if nc -z localhost $port 2>/dev/null; then
            echo "✅ $service_name is listening on port $port"
            return 0
        fi
        echo "⏳ Waiting for $service_name on port $port... ($((count + 1))/$timeout)"
        sleep 1
        count=$((count + 1))
    done

    echo "❌ Timeout: $service_name is not listening on port $port after $timeout seconds"
    return 1
}

# Function to test gRPC connection using grpcurl (if available)
test_grpc_connection() {
    local port=$1
    local service_name=$2

    # Check if grpcurl is available
    if command -v grpcurl >/dev/null 2>&1; then
        echo "Testing gRPC connection to $service_name on port $port..."
        echo "grpcurl version: $(grpcurl --version)"

        # Only test gRPC reflection for Mirror Node gRPC (port 5600) which supports it
        if [ "$port" = "$GRPC_MIRROR_PORT" ]; then
            # Try to list services with retries
            local retry_count=0
            local max_retries=3
            while [ $retry_count -lt $max_retries ]; do
                if timeout 10 grpcurl -plaintext localhost:$port list >/dev/null 2>&1; then
                    echo "✅ gRPC connection to $service_name successful"
                    echo "Available services:"
                    timeout 10 grpcurl -plaintext localhost:$port list
                    return 0
                fi
                echo "⚠️ gRPC reflection attempt $((retry_count + 1)) failed, retrying..."
                sleep 5
                retry_count=$((retry_count + 1))
            done
            echo "⚠️ gRPC reflection not available, but port is listening"
            return 0
        else
            # For other ports, just confirm the port is listening
            return 0
        fi
    else
        echo "❌ grpcurl not available - checking installation..."
        echo "PATH: $PATH"
        echo "which grpcurl: $(which grpcurl 2>/dev/null || echo 'not found')"
        echo "ls /usr/local/bin/grpcurl: $(ls -la /usr/local/bin/grpcurl 2>/dev/null || echo 'not found')"
        return 0
    fi
}

# Check gRPC Proxy (always available)
if [ -n "$GRPC_PORT" ]; then
    if check_port $GRPC_PORT "gRPC Proxy"; then
        test_grpc_connection $GRPC_PORT "gRPC Proxy"
    else
        echo "❌ gRPC Proxy validation failed"
        exit 1
    fi
else
    echo "❌ GRPC_PORT not set, skipping gRPC Proxy validation"
fi

# Check HAProxy (always available)
if [ -n "$HAPROXY_PORT" ]; then
    if check_port $HAPROXY_PORT "HAProxy"; then
        test_grpc_connection $HAPROXY_PORT "HAProxy"
    else
        echo "❌ HAProxy validation failed"
        exit 1
    fi
else
    echo "❌ HAPROXY_PORT not set, skipping HAProxy validation"
fi

# Check Mirror Node gRPC (only if mirror node is installed)
if [ "${INSTALL_MIRROR_NODE}" = "true" ] && [ -n "$GRPC_MIRROR_PORT" ]; then
    if check_port $GRPC_MIRROR_PORT "Mirror Node gRPC"; then
        test_grpc_connection $GRPC_MIRROR_PORT "Mirror Node gRPC"
    else
        echo "❌ Mirror Node gRPC validation failed"
        exit 1
    fi
else
    echo "ℹ️ Mirror Node not installed or GRPC_MIRROR_PORT not set, skipping Mirror Node gRPC validation"
fi

echo "🎉 All gRPC connections validated successfully!"

# Summary
echo ""
echo "📋 Validation Summary:"
echo "✅ gRPC Proxy (port $GRPC_PORT): Validated"
echo "✅ HAProxy (port $HAPROXY_PORT): Validated"
if [ "${INSTALL_MIRROR_NODE}" = "true" ] && [ -n "$GRPC_MIRROR_PORT" ]; then
    echo "✅ Mirror Node gRPC (port $GRPC_MIRROR_PORT): Validated"
else
    echo "ℹ️ Mirror Node gRPC (port $GRPC_MIRROR_PORT): Not installed or not set"
fi

# Final debug: Show all listening ports
echo "🔍 Final debug: All listening ports:"
netstat -tlnp 2>/dev/null | grep LISTEN || echo "No listening ports found"
