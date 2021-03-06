// (c) Vitaliy Filippov 2015+

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <stdarg.h>
#include "sophia.h"

typedef struct
{
	void *ptr;
	void *cmp;
	void *arg;
}
sophia_env_t;

typedef struct
{
	void *ptr;
}
sophia_ctl_t;

typedef struct
{
	void *ptr;
}
sophia_db_t;

typedef struct
{
	void *ptr;
}
sophia_txn_t;

typedef struct
{
	void *ptr;
}
sophia_snapshot_t;

typedef struct
{
	void *ptr;
}
sophia_cursor_t;

typedef sophia_env_t * Database__Sophia;
typedef sophia_ctl_t * Database__Sophia__Ctl;
typedef sophia_db_t * Database__Sophia__DB;
typedef sophia_txn_t * Database__Sophia__Txn;
typedef sophia_snapshot_t * Database__Sophia__Snapshot;
typedef sophia_cursor_t * Database__Sophia__Cursor;

/*static inline int sp_cmp(char *a_key, size_t asz, char *b_key, size_t bsz, void *arg)
{
	dSP;
	
	ENTER;
	SAVETMPS;
	
	sophia_t *ent = (sophia_t *)arg;
	
	PUSHMARK(sp);
		XPUSHs( sv_2mortal( newSVpv(a_key, asz) ) );
		XPUSHs( sv_2mortal( newSVpv(b_key, bsz) ) );
		if(ent->arg)
		{
			XPUSHs(ent->arg);
		}
	PUTBACK;
	
	long res = 0;
	int count = call_sv((SV *)ent->cmp, G_SCALAR);
	
	SPAGAIN;
    if (count > 0)
		res = POPi;
    PUTBACK;
	
	FREETMPS;
	LEAVE;

	return (int)res;
}*/

MODULE = Database::Sophia  PACKAGE = Database::Sophia

PROTOTYPES: DISABLE

Database::Sophia
env()
	CODE:
		sophia_env_t *env = malloc(sizeof(sophia_env_t));
		
		env->ptr = sp_env();
		env->cmp = NULL;
		env->arg = NULL;
		
		RETVAL = env;
	OUTPUT:
		RETVAL

SV*
open(env)
	Database::Sophia env;
	
	CODE:
		RETVAL = newSViv(sp_open(env->ptr));
	OUTPUT:
		RETVAL

Database::Sophia::Ctl
ctl(env)
	Database::Sophia env;
	
	CODE:
		sophia_ctl_t *ctl = malloc(sizeof(sophia_ctl_t));
		ctl->ptr = sp_ctl(env->ptr);
		RETVAL = ctl;
	OUTPUT:
		RETVAL

Database::Sophia::Txn
begin(env)
	Database::Sophia env;
	
	CODE:
		sophia_txn_t *txn = malloc(sizeof(sophia_txn_t));
		
		txn->ptr = sp_begin(env->ptr);
		
		RETVAL = txn;
	OUTPUT:
		RETVAL

void
DESTROY(ptr)
	Database::Sophia ptr;
	
	CODE:
		if(ptr)
			free(ptr);


MODULE = Database::Sophia  PACKAGE = Database::Sophia::Ctl

PROTOTYPES: DISABLE

SV*
set(ctl, key, value)
	Database::Sophia::Ctl ctl;
	SV *key;
	SV *value;
	
	CODE:
		STRLEN len_k = 0, len_v = 0;
		
		char *key_c = SvPV( key, len_k );
		char *value_c = SvPV( value, len_v );
		
		RETVAL = newSViv( sp_set(ctl->ptr, (void *)key_c, (void *)value_c ) );
	OUTPUT:
		RETVAL

SV*
get(ctl, key)
	Database::Sophia::Ctl ctl;
	SV *key;
	
	CODE:
		STRLEN len_k = 0;
		char *key_c = SvPV( key, len_k );
		void *obj = sp_get(ctl->ptr, (void*)key_c);
		if (!obj)
		{
			RETVAL = &PL_sv_undef;
		}
		else
		{
			char *t = sp_type(obj);
			if (!t)
			{
				croak("Object of empty type returned from ctl sp_get");
			}
			else if (!strcmp(t, "database"))
			{
				sophia_db_t *db = malloc(sizeof(sophia_db_t));
				db->ptr = obj;
				RETVAL = sv_newmortal();
				sv_setref_pv(RETVAL, "Database::Sophia::DB", (void *)db);
				SvREFCNT_inc(RETVAL);
			}
			else if (!strcmp(t, "snapshot"))
			{
				sophia_snapshot_t *snapshot = malloc(sizeof(sophia_snapshot_t));
				snapshot->ptr = obj;
				RETVAL = sv_newmortal();
				sv_setref_pv(RETVAL, "Database::Sophia::Snapshot", (void *)snapshot);
				SvREFCNT_inc(RETVAL);
			}
			else if (!strcmp(t, "object"))
			{
				uint32_t l;
				char *r = (char*)sp_get(obj, "value", &l);
				RETVAL = newSVpv(r, l);
				sp_destroy(obj);
			}
			else
			{
				croak("Unknown object type returned from ctl sp_get: %s", t);
			}
		}
	OUTPUT:
		RETVAL

Database::Sophia::Cursor
cursor(ctl)
	Database::Sophia::Ctl ctl;
	
	CODE:
		sophia_cursor_t *cur = malloc(sizeof(sophia_cursor_t));
		cur->ptr = sp_cursor(ctl->ptr);
		RETVAL = cur;
	OUTPUT:
		RETVAL

void
DESTROY(ptr)
	Database::Sophia::Ctl ptr;
	
	CODE:
		if(ptr)
			free(ptr);


MODULE = Database::Sophia  PACKAGE = Database::Sophia::DB

Database::Sophia::Ctl
ctl(db)
	Database::Sophia::DB db;
	
	CODE:
		sophia_ctl_t *ctl = malloc(sizeof(sophia_ctl_t));
		ctl->ptr = sp_ctl(db->ptr);
		RETVAL = ctl;
	OUTPUT:
		RETVAL

SV*
open(db)
	Database::Sophia::DB db;
	
	CODE:
		RETVAL = newSViv(sp_open(db->ptr));
	OUTPUT:
		RETVAL

SV*
get(db, key, txn_or_snapshot = &PL_sv_undef)
	Database::Sophia::DB db;
	SV *key;
	SV *txn_or_snapshot;
	
	CODE:
		STRLEN len_k = 0;
		char *key_c = SvPV(key, len_k);
		void *value;
		size_t size;
		
		RETVAL = &PL_sv_undef;
		void *obj = sp_object(db->ptr);
		void *ret;
		if (obj)
		{
			sp_set(obj, "key", key_c, len_k);
			ret = sp_get(SvOK(txn_or_snapshot) ? (INT2PTR(sophia_txn_t*, (SvIV((SV*)SvRV(txn_or_snapshot)))))->ptr : db->ptr, obj);
			if (ret)
			{
				value = sp_get(ret, "value", &size);
				RETVAL = newSVpv(value, size);
				sp_destroy(ret);
			}
			sp_destroy(obj);
		}
	OUTPUT:
		RETVAL

SV*
delete(db, key, txn = &PL_sv_undef)
	Database::Sophia::DB db;
	SV *key;
	SV *txn;
	
	CODE:
		int err = -1;
		STRLEN len_k = 0;
		char *key_c = SvPV(key, len_k);
		
		RETVAL = &PL_sv_undef;
		void *obj = sp_object(db->ptr);
		if (obj)
		{
			sp_set(obj, "key", key_c, len_k);
			err = sp_delete(SvOK(txn) ? (INT2PTR(sophia_txn_t*, (SvIV((SV*)SvRV(txn)))))->ptr : db->ptr, obj);
			sp_destroy(obj);
		}
		RETVAL = newSViv(err);
	OUTPUT:
		RETVAL

SV*
set(db, key, value, txn = &PL_sv_undef)
	Database::Sophia::DB db;
	SV *key;
	SV *value;
	SV *txn;
	
	CODE:
		int err = -1;
		STRLEN len_k = 0;
		char *key_c = SvPV(key, len_k);
		STRLEN len_v = 0;
		char *value_c = SvPV(value, len_v);
		
		RETVAL = &PL_sv_undef;
		void *obj = sp_object(db->ptr);
		if (obj)
		{
			sp_set(obj, "key", key_c, len_k);
			sp_set(obj, "value", value_c, len_v);
			err = sp_set(SvOK(txn) ? (INT2PTR(sophia_txn_t*, (SvIV((SV*)SvRV(txn)))))->ptr : db->ptr, obj);
			sp_destroy(obj);
		}
		RETVAL = newSViv(err);
	OUTPUT:
		RETVAL

Database::Sophia::Cursor
cursor(db, key, order, snapshot = &PL_sv_undef)
	Database::Sophia::DB db;
	SV *key;
	SV *order;
	SV *snapshot;
	
	CODE:
		void *c;
		STRLEN len_k = 0;
		char *key_c = SvPV(key, len_k);
		STRLEN len_o = 0;
		char *order_c = SvPV(order, len_o);
		void *obj = sp_object(db->ptr);
		
		RETVAL = (void*)&PL_sv_undef;
		if (obj)
		{
			sp_set(obj, "key", key_c, len_k);
			sp_set(obj, "order", order_c, len_o);
			c = sp_cursor(SvOK(snapshot) ? (INT2PTR(sophia_snapshot_t*, (SvIV((SV*)SvRV(snapshot)))))->ptr : db->ptr, obj);
			sp_destroy(obj);
			if (c)
			{
				sophia_cursor_t *cur = malloc(sizeof(sophia_cursor_t));
				cur->ptr = c;
				RETVAL = cur;
			}
		}
	OUTPUT:
		RETVAL

void
DESTROY(ptr)
	Database::Sophia::DB ptr;
	
	CODE:
		if(ptr->ptr)
			sp_destroy(ptr->ptr);
		if(ptr)
			free(ptr);


MODULE = Database::Sophia  PACKAGE = Database::Sophia::Txn

PROTOTYPES: DISABLE

SV*
commit(txn)
	Database::Sophia::Txn txn;
	
	CODE:
		RETVAL = newSViv( sp_commit(txn->ptr) );
		// FIXME destroy
	OUTPUT:
		RETVAL

void
DESTROY(ptr)
	Database::Sophia::Txn ptr;
	
	CODE:
		if(ptr->ptr)
			sp_destroy(ptr->ptr);
		if(ptr)
			free(ptr);


MODULE = Database::Sophia  PACKAGE = Database::Sophia::Snapshot

PROTOTYPES: DISABLE

SV*
drop(snapshot)
	Database::Sophia::Snapshot snapshot;
	
	CODE:
		RETVAL = newSViv( sp_drop(snapshot->ptr) );
		// FIXME destroy
	OUTPUT:
		RETVAL

void
DESTROY(ptr)
	Database::Sophia::Snapshot ptr;
	
	CODE:
		if(ptr->ptr)
			sp_destroy(ptr->ptr);
		if(ptr)
			free(ptr);


MODULE = Database::Sophia  PACKAGE = Database::Sophia::Cursor

PROTOTYPES: DISABLE

SV*
next_key(cursor)
	Database::Sophia::Cursor cursor;
	
	CODE:
		void *obj = sp_get(cursor->ptr);
		uint32_t size;
		char *value;
		if (obj)
		{
			value = sp_get(obj, "key", &size);
			RETVAL = newSVpv(value, size);
		}
		else
		{
			RETVAL = &PL_sv_undef;
		}
	OUTPUT:
		RETVAL

SV*
cur_key(cursor)
	Database::Sophia::Cursor cursor;
	
	CODE:
		void *obj = sp_object(cursor->ptr);
		uint32_t size;
		char *value;
		if (obj)
		{
			value = sp_get(obj, "key", &size);
			RETVAL = newSVpv(value, size);
		}
		else
		{
			RETVAL = &PL_sv_undef;
		}
	OUTPUT:
		RETVAL

SV*
cur_value(cursor)
	Database::Sophia::Cursor cursor;
	
	CODE:
		void *obj = sp_object(cursor->ptr);
		uint32_t size;
		char *value;
		if (obj)
		{
			value = sp_get(obj, "value", &size);
			RETVAL = newSVpv(value, size);
		}
		else
		{
			RETVAL = &PL_sv_undef;
		}
	OUTPUT:
		RETVAL

void
DESTROY(ptr)
	Database::Sophia::Snapshot ptr;
	
	CODE:
		if(ptr->ptr)
			sp_destroy(ptr->ptr);
		if(ptr)
			free(ptr);
