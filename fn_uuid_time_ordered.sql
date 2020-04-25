-- returns a time-ordered UUID (v6)
create or replace function fn_uuid_time_ordered() returns varchar as $$
declare
	i        integer;
	v_md5    varchar;
	v_bytes  bytea;
	v_byte   bit(8);
	v_uuid   varchar;

    v_greg bigint := EXTRACT(EPOCH from '1582-10-15 00:00:00'::timestamp);
    v_time timestamp with time zone:= null;
	v_secs bigint := null;
    v_msec bigint := null;
	v_timestamp bigint := null;
    v_timestamp_hex bytea := null;
begin

	-- Get current seconds and microseconds
	v_time := current_timestamp; 
	v_secs := EXTRACT(EPOCH FROM v_time);
	v_msec := EXTRACT(MICROSECONDS FROM v_time);

	-- Calculate the timestamp
	v_timestamp := (((v_secs - v_greg) * 10^6) + v_msec) * 10;

	-- Format the timestamp to hexadecimal
	v_timestamp_hex := substr('0000000000000000', 1, 16 - length(to_hex(v_timestamp))) || to_hex(v_timestamp);
	v_timestamp_hex := substr(v_timestamp_hex, 2, 12) || '0' || substr(v_timestamp_hex, 14, 3);

	-- Get a random hex
	v_md5 := md5(current_timestamp::text || random()::text);

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
-- 1ea869ac-2b86-6090-88a0-36c0ab3b7d7d
