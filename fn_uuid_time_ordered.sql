
/**
 * Returns a time-ordered UUID (v6).
 * 
 * The multicast bit is set automatically in the node identifier.
 * 
 * Tags: uuid guid uuid-generator guid-generator generator time order rfc4122 rfc-4122
 *
 * @param p_node the node identifier (0 to 2^48)
 */
create or replace function fn_uuid_time_ordered(p_node bigint) returns varchar as $$
declare
	i        integer;
	v_rnd    float8;
	v_md5    varchar;
	v_bytes  bytea;
	v_byte   bit(8);

	v_time timestamp with time zone:= null;
	v_secs bigint := null;
	v_msec bigint := null;
	v_timestamp bigint := null;
	v_timestamp_hex bytea := null;
	v_variant varchar;
	v_node varchar;

	c_node_max bigint := (2^48)::bigint; -- 6 bytes
	c_greg bigint := EXTRACT(EPOCH from '1582-10-15 00:00:00'::timestamp); -- Gragorian epoch
begin

	-- Get time and random values
	v_time := clock_timestamp();
	v_rnd := random();

	-- Extract seconds and microseconds
	v_secs := EXTRACT(EPOCH FROM v_time);
	v_msec := mod(EXTRACT(MICROSECONDS FROM v_time)::numeric, 10^6::numeric); -- MOD() to remove seconds

	-- Calculate the timestamp
	v_timestamp := (((v_secs - c_greg) * 10^6) + v_msec) * 10;

	-- Generate timestamp hexadecimal (and set version number)
	v_timestamp_hex := lpad(to_hex(v_timestamp), 16, '0');
	v_timestamp_hex := substr(v_timestamp_hex, 2, 12) || '6' || substr(v_timestamp_hex, 14, 3);

	-- Generate a random hexadecimal
	v_md5 := md5(v_time::text || v_rnd::text);
	
	-- Concat timestemp hex with random hex
	v_md5 := v_timestamp_hex || substr(v_md5, 1, 16);

	-- Insert the node identifier
	if p_node is not null then
	
		v_node := to_hex(p_node % c_node_max);
		v_node := lpad(v_node, 12, '0');
		v_md5 := overlay(v_md5 placing v_node from 21);
	
	end if;

	-- Set variant number
	v_bytes := decode(substring(v_md5, 17, 2), 'hex');
	v_byte := get_byte(v_bytes, 0)::bit(8);
	v_byte := v_byte & x'3f';
	v_byte := v_byte | x'80';
	v_bytes := set_byte(v_bytes, 0, v_byte::integer);
	v_variant := encode(v_bytes, 'hex')::varchar;
	v_md5 := overlay(v_md5 placing v_variant from 17);

	-- Set multicast bit
	v_bytes := decode(substring(v_md5, 21, 2), 'hex');
	v_byte := get_byte(v_bytes, 0)::bit(8);
	v_byte := v_byte | x'01';
	v_bytes := set_byte(v_bytes, 0, v_byte::integer);
	v_variant := encode(v_bytes, 'hex')::varchar;
	v_md5 := overlay(v_md5 placing v_variant from 21);

	return v_md5::uuid::varchar;
	
end $$ language plpgsql;

/**
 * Returns a time-ordered UUID (v6)
 * 
 * Tags: uuid guid uuid-generator guid-generator generator time order rfc4122 rfc-4122
 *
 * The node identifier is random and multicast.
 */
create or replace function fn_uuid_time_ordered() returns varchar as $$
declare
begin
	return fn_uuid_time_ordered(null);
end $$ language plpgsql;

-- EXAMPLE 1:
-- select fn_uuid_time_ordered(1024);

-- EXAMPLE OUTPUT:
-- 1ea8a97d-4f60-60e0-9bbf-010000000400

-- EXAMPLE 2:
-- select fn_uuid_time_ordered();

-- EXAMPLE 2 OUTPUT: 
-- 1ea8a97d-e70c-66c0-9d62-41c86b14b02e

