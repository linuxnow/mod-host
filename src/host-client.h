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

#ifndef HOST_CLIENT_H
#define HOST_CLIENT_H


/*
************************************************************************************************************************
*           INCLUDE FILES
************************************************************************************************************************
*/

#include <stddef.h>


/*
************************************************************************************************************************
*           CONFIGURATION DEFINES
************************************************************************************************************************
*/

/* Longest client name tried, NUL included; the name limit the caller passes is capped to it */
#define HOST_CLIENT_NAME_BUF_SIZE   256


/*
************************************************************************************************************************
*           DATA TYPES
************************************************************************************************************************
*/

/* Opens a client called 'name'. With 'exact' set the name may not be changed by the server, and
   'name_taken' is set when another client already has it. Returns the client or NULL. */
typedef void *(*host_client_open_fn)(const char *name, int exact, int *name_taken, void *arg);


/*
************************************************************************************************************************
*           FUNCTION PROTOTYPES
************************************************************************************************************************
*/

/* The client of the effect 'instance', named after 'requested_name' when there is one: ':' becomes
   '_' and the name is cut to 'name_limit' characters; a name already taken is retried with
   "_<instance>" appended inside that limit; when no requested name sticks, the client is the
   default "effect_<instance>", so an add never fails because of the name it asked for. */
void *host_client_open(int instance, const char *requested_name, size_t name_limit,
                       host_client_open_fn open_fn, void *arg);


/*
************************************************************************************************************************
*           END HEADER
************************************************************************************************************************
*/

#endif
