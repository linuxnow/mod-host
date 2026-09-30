/*
 * This file is part of mod-host.
 *
 * mod-host is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * mod-host is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with mod-host.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

/*
 * What libmod-host-protocol keeps to itself. The library's objects build with -fvisibility=hidden,
 * so a function is exported only when its definition carries MOD_HOST_PROTOCOL_EXPORT; the exports
 * are the ones a host links (mod-host, omx-clap-host, plugin-hostd and the scenario runner), listed
 * in abi/. The functions below are not exported: they serve the library itself and its own tests,
 * which link the objects, and this header is never installed.
 */

#ifndef PROTOCOL_INTERNAL_H
#define PROTOCOL_INTERNAL_H

#include <stddef.h>
#include <stdint.h>

#include "host-backend.h"
#include "protocol.h"

#if defined(__GNUC__) && !defined(_WIN32)
#define MOD_HOST_PROTOCOL_EXPORT __attribute__((visibility("default")))
#else
#define MOD_HOST_PROTOCOL_EXPORT
#endif

/* utils.c */
// returns the string array length
uint32_t strarr_length(char **str_array);
// joins a string array in a single string
char* strarr_join(char** const str_array);

/* protocol.c: the text protocol_parse() answers for one of its PROTOCOL_* errors */
const char *protocol_error_message(int code);

/* host-dispatch.c: the callback host_dispatch_register_unsupported() gives each verb it answers -902 */
void host_dispatch_unsupported_cb(proto_t *proto);

/* host-scenario.c: a backend in this process driven through the protocol parser over a socketpair */
typedef struct HOST_SCENARIO_DIRECT_T {
    int fd[2];
    const host_backend_t *backend;
} host_scenario_direct_t;

int host_scenario_direct_open(host_scenario_direct_t *direct, const host_backend_t *backend);
int host_scenario_direct_exchange(void *ctx, const char *command, char *reply, size_t size);
void host_scenario_direct_close(host_scenario_direct_t *direct);

#endif
