
/**
 * Returns a time-ordered UUID (v6).
 * 
 * Tags: uuid guid uuid-generator guid-generator generator time order rfc4122 rfc-4122
 */
create or replace function fn_uuid_time_ordered() returns uuid as $$
declare
	v_time timestamp with time zone:= null;
	v_secs bigint := null;
	v_usec bigint := null;
	v_timestamp bigint := null;
	v_timestamp_hex varchar := null;
	v_bytes  bytea;

	c_greg bigint :=  -12219292800; -- Gragorian epoch: '1582-10-15 00:00:00'
begin

	-- Get time and random values
	v_time := clock_timestamp();

	-- Extract seconds and microseconds
	v_secs := EXTRACT(EPOCH FROM v_time);
	v_usec := mod(EXTRACT(MICROSECONDS FROM v_time)::numeric, 10^6::numeric);

	-- Calculate the timestamp
	v_timestamp := (((v_secs - c_greg) * 10^6) + v_usec) * 10;

	-- Generate timestamp hexadecimal (and set version number: 6)
	v_timestamp_hex := lpad(to_hex(v_timestamp), 16, '0');
	v_timestamp_hex := substr(v_timestamp_hex, 2, 12) || '6' || substr(v_timestamp_hex, 14, 3);

	-- Concat timestemp hex with random hex to generate a byte array
	v_bytes := decode(substr(v_timestamp_hex || md5(random()::text), 1, 32), 'hex');

	-- Set variant bits (10xx)
	v_bytes := set_bit(v_bytes, 71, 1);
	v_bytes := set_bit(v_bytes, 70, 0);

	return encode(v_bytes, 'hex')::uuid;
	
end $$ language plpgsql;

-- EXAMPLE:
-- 
-- select fn_uuid_time_ordered() uuid, clock_timestamp()-statement_timestamp() time_taken;

-- EXAMPLE OUTPUT:
-- 
-- |uuid                                  |time_taken        |
-- |--------------------------------------|------------------|
-- |1ec4c81e-ac69-61e0-8021-798ee3338c84  |00:00:00.000243   |

