#!/bin/sh

. /lib/netifd/netifd-proto.sh
init_proto "$@"

proto_ssh_tunnel_init_config() {
	proto_config_add_string server
	proto_config_add_int port
	proto_config_add_string username
	proto_config_add_string password
	proto_config_add_string identity_file
	proto_config_add_boolean disabled
}

proto_ssh_tunnel_setup() {
	local interface="$1" server port username password identity_file device disabled
	json_get_vars server port username password identity_file disabled
	[ -n "$server" ] && [ -n "$username" ] || { proto_notify_error "$interface" NO_SERVER; return; }
	port="${port:-22}"
	[ -n "$identity_file" ] || [ -n "$password" ] || { proto_notify_error "$interface" NO_CREDENTIALS; return; }
	device="st$(printf '%s' "$interface" | md5sum | cut -c1-13)"
	if ! /usr/libexec/ssh-tunnel-client --create "$device"; then
		/usr/libexec/ssh-tunnel-client --delete "$device" >/dev/null 2>&1
		proto_notify_error "$interface" TUN_CREATE_FAILED
		return
	fi
	proto_init_update "$device" 1
	proto_add_ipv4_address 172.31.255.2 30 172.31.255.1
	proto_send_update "$interface"
	if [ -n "$identity_file" ]; then
		proto_run_command "$interface" /usr/libexec/ssh-tunnel-client "$server" "$port" "$username" "$device" "$identity_file" key
	else
		proto_run_command "$interface" /usr/bin/env "SSHPASS=$password" /usr/libexec/ssh-tunnel-client "$server" "$port" "$username" "$device" - password
	fi
}

proto_ssh_tunnel_teardown() {
	local interface="$1" device
	device="st$(printf '%s' "$interface" | md5sum | cut -c1-13)"
	proto_kill_command "$interface"
	/usr/libexec/ssh-tunnel-client --delete "$device" >/dev/null 2>&1
}

add_protocol ssh_tunnel
