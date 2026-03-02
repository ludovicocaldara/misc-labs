output "demo_vm" {
  value = format("Your demo VM is ready with public IP address %s", oci_core_instance.demo_vm.public_ip)
}

output "adb" {
  value = format("Your Autonomous Database is ready with sql_web address: %s", oci_database_autonomous_database.demo_adb.connection_urls[0].sql_dev_web_url)
}

output "private_key" {
  value = format("Get the private key for demo_vm with: echo 'nonsensitive(tls_private_key.provisioner_keypair.private_key_pem)' | terraform console")
}

output "adb_password" {
  value = format("Get the Autonomous Database password with: echo 'nonsensitive(random_password.adb_password.result)' | terraform console")
}

output "adb_wallet_password" {
  value = format("Get the Autonomous Database wallet password with: echo 'nonsensitive(random_password.adb_wallet_password.result)' | terraform console")
}
