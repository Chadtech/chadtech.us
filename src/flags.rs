use std::env;

////////////////////////////////////////////////////////////////////////////////
// TYPES //
////////////////////////////////////////////////////////////////////////////////

pub struct Flags {
    pub ip_address: String,
    pub admin_password: String,
    pub port_number: u64,
    pub dev_mode: bool,
    pub show_elm_output: bool,
}

impl Flags {
    pub fn poca() -> Result<Flags, String> {
        let mut args: Vec<String> = env::args().collect();

        args.remove(0);

        let mut maybe_ip_address: Result<String, String> = Err("ip address not set".to_string());

        let mut maybe_admin_password: Result<String, String> =
            Err("admin password not set".to_string());

        let mut maybe_port: Result<u64, String> = Err("port number not set".to_string());

        let mut dev_mode = false;

        let mut show_elm_output = true;

        for arg in args {
            let mut dev = || {
                maybe_ip_address = Ok("127.0.0.1".to_string());
                maybe_admin_password = Ok("password".to_string());
                maybe_port = Ok(8080);
                dev_mode = true;
            };

            match arg.find('=') {
                None => match arg.as_str() {
                    "dev" => dev(),

                    "dev-backend" => {
                        dev();
                        show_elm_output = false;
                    }

                    arg_str => {
                        let mut buf = String::new();

                        buf.push_str("Unrecognized arg : ");
                        buf.push_str(arg_str);

                        return Err(buf);
                    }
                },
                Some(index) => {
                    let (key, value_str) = arg.split_at(index);

                    let mut value = value_str.to_string();
                    value.remove(0);

                    match key {
                        "ip_address" => {
                            maybe_ip_address = Ok(value.to_string());
                        }
                        "admin_password" => {
                            maybe_admin_password = Ok(value.to_string());
                        }
                        "port" => match value.parse::<u64>() {
                            Ok(port) => {
                                maybe_port = Ok(port);
                            }
                            Err(error) => {
                                let mut buf = String::new();

                                buf.push_str("port is not a number : ");
                                buf.push_str(error.to_string().as_str());

                                return Err(buf);
                            }
                        },
                        unrecognized_key => {
                            let mut buf = String::new();

                            buf.push_str("Unrecognized key : ");
                            buf.push_str(unrecognized_key);

                            return Err(buf);
                        }
                    }
                }
            }
        }

        let ip_address = maybe_ip_address?;
        let admin_password = maybe_admin_password?;
        let port_number = maybe_port?;

        Ok(Flags {
            ip_address,
            admin_password,
            dev_mode,
            port_number,
            show_elm_output,
        })
    }
}
