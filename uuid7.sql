/**
 * Returns a time-ordered with Unix Epoch UUID (UUIDv7).
 * 
 * Tags: uuid guid uuid-generator guid-generator generator time order rfc4122 rfc-4122
 */
create or replace function uuid7() returns uuid as $$
declare
	v_time timestamp with time zone:= null;
	v_secs bigint := null;
	v_usec bigint := null;

	v_timestamp bigint := null;
	v_timestamp_hex varchar := null;

	v_random bigint := null;
	v_random_hex varchar := null;

	v_bytes bytea;

	c_variant bit(64):= x'8000000000000000'; -- RFC-4122 variant: b'10xx...'
begin

	-- Get seconds and micros
	v_time := clock_timestamp();
	v_secs := EXTRACT(EPOCH FROM v_time);
	v_usec := mod(EXTRACT(MICROSECONDS FROM v_time)::numeric, 10^6::numeric);

	-- Generate timestamp hexadecimal (and set version 7)
	v_timestamp := ((v_secs * 10^6) + v_usec) * 10;
	v_timestamp_hex := lpad(to_hex(v_timestamp), 16, '0');
	v_timestamp_hex := substr(v_timestamp_hex, 2, 12) || '7' || substr(v_timestamp_hex, 14, 3);

	-- Generate the random hexadecimal (and set variant b'10xx')
	v_random := ((random()::numeric * 2^62::numeric)::bigint::bit(64) | c_variant)::bigint;
	v_random_hex := lpad(to_hex(v_random), 16, '0');

	-- Concat timestemp and random hexadecimal
	v_bytes := decode(v_timestamp_hex || v_random_hex, 'hex');

	return encode(v_bytes, 'hex')::uuid;
	
end $$ language plpgsql;

-- EXAMPLE:
-- 
-- select uuid7() uuid, clock_timestamp()-statement_timestamp() time_taken;

-- EXAMPLE OUTPUT:
-- 
-- |uuid                                  |time_taken        |
-- |--------------------------------------|------------------|
-- |03bbc855-0195-7dca-9cf5-c4e66abbc1a2  |00:00:00.000062   |

-------------------------------------------------------------------
-- FOR TEST: the expected result is an empty result set
-------------------------------------------------------------------
-- with t as (
--     select uuid7() as id from generate_series(1, 1000)
-- )
-- select * from t
-- where (id is null or id::text !~ '^[a-f0-9]{8}-[a-f0-9]{4}-6[a-f0-9]{3}-[89ab][a-f0-9]{3}-[a-f0-9]{12}$');

