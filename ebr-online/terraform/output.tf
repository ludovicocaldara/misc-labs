output "demo_vm" {
  value = format("Your demo VM is ready with public IP address %s", oci_core_instance.demo_vm.public_ip)
}

output "adb" {
  value = format("Your Autonomous Database is ready with sql_web address: %s", oci_database_autonomous_database.demo_adb.connection_urls[0].sql_dev_web_url)
}
