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
************************************************************************************************************************
*
************************************************************************************************************************
*/


/*
************************************************************************************************************************
*           INCLUDE FILES
************************************************************************************************************************
*/

#include <stdio.h>
#include <string.h>

#include "host-client.h"


/*
************************************************************************************************************************
*           LOCAL FUNCTIONS
************************************************************************************************************************
*/

/* ':' is the port separator: a client name carrying one would make its own ports unparseable */
static void sanitize_client_name(char *dst, size_t dst_size, const char *src, size_t max_len)
{
    if (max_len >= dst_size) max_len = dst_size - 1;
    size_t di = 0;
    for (size_t si = 0; src[si] != '\0' && di < max_len; si++)
    {
        dst[di++] = (src[si] == ':') ? '_' : src[si];
    }
    dst[di] = '\0';
}


/*
************************************************************************************************************************
*           GLOBAL FUNCTIONS
************************************************************************************************************************
*/

void *host_client_open(int instance, const char *requested_name, size_t name_limit,
                       host_client_open_fn open_fn, void *arg)
{
    char effect_name[32];
    char requested[HOST_CLIENT_NAME_BUF_SIZE];
    int name_taken = 0;
    void *client;

    snprintf(effect_name, sizeof(effect_name), "effect_%i", instance);

    if (!requested_name || requested_name[0] == '\0')
        return open_fn(effect_name, 0, &name_taken, arg);

    sanitize_client_name(requested, sizeof(requested), requested_name, name_limit);
    if (requested[0] == '\0')
        return open_fn(effect_name, 0, &name_taken, arg);

    /* exact, so a collision is reported rather than silently mangled into a name the caller
       cannot predict */
    client = open_fn(requested, 1, &name_taken, arg);

    if (!client && name_taken)
    {
        char suffixed[HOST_CLIENT_NAME_BUF_SIZE];
        char id_suffix[16];
        size_t limit = name_limit < sizeof(suffixed) - 1 ? name_limit : sizeof(suffixed) - 1;

        snprintf(id_suffix, sizeof(id_suffix), "_%i", instance);
        size_t base_len = strlen(requested);
        size_t suffix_len = strlen(id_suffix);
        size_t keep = (base_len + suffix_len <= limit)
                          ? base_len
                          : (limit > suffix_len ? limit - suffix_len : 0);
        memcpy(suffixed, requested, keep);
        memcpy(suffixed + keep, id_suffix, suffix_len + 1);

        name_taken = 0;
        client = open_fn(suffixed, 1, &name_taken, arg);
    }

    if (!client)
        client = open_fn(effect_name, 0, &name_taken, arg);

    return client;
}
