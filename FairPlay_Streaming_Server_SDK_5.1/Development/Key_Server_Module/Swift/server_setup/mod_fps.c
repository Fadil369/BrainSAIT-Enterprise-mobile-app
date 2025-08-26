//
// Copyright © 2023-2025 Apple Inc. All rights reserved.
//

#include "httpd.h"
#include "http_config.h"
#include "http_protocol.h"
#include "ap_config.h"
#include <stdio.h>
#include <stdint.h>

extern int fpsProcessOperations(const char *in_json, int in_json_size, char **out_json, int *out_json_size);
extern int fpsDisposeResponse(char *out_pay_load, int out_pay_load_sz);

static int fps_handler(request_rec *r) {

    if (!r->handler || strcmp(r->handler, "fps_handler")) {
        return DECLINED;
    }

    if (r->method_number != M_POST) {
        return HTTP_METHOD_NOT_ALLOWED;
    }

    r->content_type = "text/plain";

    // Read the body of the request
    if (r->header_only) {
        return OK;
    }

    // Ensure request body is present
    if (ap_setup_client_block(r, REQUEST_CHUNKED_ERROR)) {
        return HTTP_INTERNAL_SERVER_ERROR;
    }
    if (!ap_should_client_block(r)) {
        return HTTP_INTERNAL_SERVER_ERROR;
    }

    // Allocate buffer and read request body
    apr_size_t buffer_size = r->remaining > 0 ? r->remaining : 16384;
    char *buffer = apr_palloc(r->pool, buffer_size);
    int bytes;
    apr_size_t length = 0;
    while ((bytes = ap_get_client_block(r, buffer + length, buffer_size - length)) > 0) {
        length += bytes;
    }
    buffer[length] = '\0'; // Null-terminate the string

    char *outJson = NULL;
    int outJsonSize = 0;
    int status = fpsProcessOperations(buffer, strlen(buffer), &outJson, &outJsonSize);
    if (status != 0) {
        ap_rprintf(r, "fpsProcessOperations failed with status %d\n", status);
    }

    ap_rprintf(r, "%s\n", outJson);

    // Free output json memory
    status = fpsDisposeResponse(outJson, outJsonSize);
    if (status != 0) {
        ap_rprintf(r, "fpsDisposeResponse failed with status %d\n", status);
    }

    return OK;
}

static void register_hooks(apr_pool_t *pool) {
    ap_hook_handler(fps_handler, NULL, NULL, APR_HOOK_MIDDLE);
}

module AP_MODULE_DECLARE_DATA fps_module = {
    STANDARD20_MODULE_STUFF,
    NULL,                  // Per-directory configuration handler
    NULL,                  // Merge handler for per-directory configurations
    NULL,                  // Per-server configuration handler
    NULL,                  // Merge handler for per-server configurations
    NULL,                  // Any directives we may have for httpd
    register_hooks         // Our hook registering function
};