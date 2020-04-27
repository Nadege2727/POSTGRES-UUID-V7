-- returns a time-ordered UUID (v6)
create or replace function fn_uuid_time_ordered() returns varchar as $$
declare
	i        integer;
	v_rnd    float8;
	v_md5    varchar;
	v_bytes  bytea;
	v_byte   bit(8);
	v_uuid   varchar;

	v_time timestamp with time zone:= null;
	v_secs bigint := null;
	v_msec bigint := null;
	v_timestamp bigint := null;
	v_timestamp_hex bytea := null;

	c_greg bigint := EXTRACT(EPOCH from '1582-10-15 00:00:00'::timestamp); -- Gragorian epoch
begin

	-- Get time and random values
	v_time := current_timestamp;
	v_rnd := random(); 

	-- Extract seconds and microseconds
	v_secs := EXTRACT(EPOCH FROM v_time);
	v_msec := mod(EXTRACT(MICROSECONDS FROM v_time)::numeric, 10^6::numeric); -- MOD() to remove seconds

	-- Calculate the timestamp
	v_timestamp := (((v_secs - c_greg) * 10^6) + v_msec) * 10;

	-- Generate timestamp hexadecimal
	v_timestamp_hex := lpad(to_hex(v_timestamp), 16, '0');
	v_timestamp_hex := substr(v_timestamp_hex, 2, 12) || '0' || substr(v_timestamp_hex, 14, 3);

	-- Generate a random hexadecimal
	v_md5 := md5(v_time::text || v_rnd::text);

	-- Concat timestemp hex with random hex
	v_md5 := v_timestamp_hex || substr(v_md5, 1, 16);

	i = 1;
	v_bytes := '';
	while i <= 32 loop
		v_bytes := v_bytes || decode(substring(v_md5, i, 2), 'hex');
		i := i + 2;
	end loop;

	-- Set version number
	v_byte := get_byte(v_bytes, 6)::bit(8);
	v_byte := v_byte & x'0f';
	v_byte := v_byte | x'60';
	v_bytes := set_byte(v_bytes, 6, v_byte::integer);

	-- Set variant number
	v_byte := get_byte(v_bytes, 8)::bit(8);
	v_byte := v_byte & x'3f';
	v_byte := v_byte | x'80';
	v_bytes := set_byte(v_bytes, 8, v_byte::integer);

	i := 1;
	v_uuid := '';
	while i <= 32 loop
		if i = 5 or i = 7 or i = 9 or i = 11
		then
			v_uuid := v_uuid || '-';
			v_uuid := v_uuid || encode(substring(v_bytes, i, 1), 'hex');
		else 
			v_uuid := v_uuid || encode(substring(v_bytes, i, 1), 'hex');
		end if;
		i := i + 1;
	end loop;

	return v_uuid;
	
end $$ language plpgsql;

-- EXAMPLE:
-- select fn_uuid_time_ordered();

-- EXAMPLE OUTPUT: 
-- 1ea86b42-ad60-6d8c-86d0-4e0e3ef2215a
