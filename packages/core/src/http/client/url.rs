use crate::http::client::scoped_host;
use std::borrow::Cow;

pub struct TargetUrl<'a> {
    pub version: ApiVersion,
    pub protocol: &'static str,
    pub host: String,
    pub port: u16,
    pub path: &'static str,

    /// Query parameters as key-value pairs.
    /// Note: It is expected that the caller will URL-encode the values if necessary.
    pub params: &'a [(&'static str, &'a str)],
}

pub enum ApiVersion {
    V2,
    V3,
}

impl<'a> TargetUrl<'a> {
    pub fn to_string(&self) -> String {
        let endpoint = match self.path {
            "/register" => "/v1/node/handshake",
            "/info" => "/v1/node/status",
            "/prepare-upload" => "/v1/transfer/initiate",
            "/upload" => "/v1/transfer/stream",
            "/cancel" => "/v1/transfer/abort",
            "/show" => "/v1/system/bring-to-front",
            "/prepare-download" => "/v1/download/initiate",
            "/download" => "/v1/download/stream",
            other => other,
        };
        let base = format!(
            "{}://{}:{}{}",
            self.protocol,
            // A scoped IPv6 address (`fe80::1%3`) cannot be represented in a
            // URL and becomes a synthetic host name instead.
            match scoped_host::encode(&self.host) {
                Some(encoded) => Cow::Owned(encoded),
                None => match self.host.contains(':') {
                    true => Cow::Owned(format!("[{}]", self.host)), // IPv6 addresses need to be enclosed in brackets
                    false => Cow::Borrowed(&self.host),
                },
            },
            self.port,
            endpoint
        );
        if self.params.is_empty() {
            base
        } else {
            let query = self
                .params
                .iter()
                .map(|(k, v)| format!("{}={}", k, v))
                .collect::<Vec<_>>()
                .join("&");
            format!("{}?{}", base, query)
        }
    }
}

#[cfg(test)]
mod tests {
    use super::{ApiVersion, TargetUrl};

    #[test]
    fn test_build_url_ipv4() {
        let url = TargetUrl {
            version: ApiVersion::V2,
            protocol: "https",
            host: "192.168.1.1".to_string(),
            port: 48855,
            path: "/register",
            params: &[],
        }
        .to_string();
        assert_eq!(url, "https://192.168.1.1:48855/v1/node/handshake");
    }

    #[test]
    fn test_build_url_ipv6() {
        let url = TargetUrl {
            version: ApiVersion::V2,
            protocol: "https",
            host: "::1".to_string(),
            port: 48855,
            path: "/register",
            params: &[],
        }
        .to_string();
        assert_eq!(url, "https://[::1]:48855/v1/node/handshake");
    }

    #[test]
    fn test_build_url_scoped_ipv6() {
        let url = TargetUrl {
            version: ApiVersion::V2,
            protocol: "https",
            host: "fe80::1%3".to_string(),
            port: 48855,
            path: "/register",
            params: &[],
        }
        .to_string();
        assert_eq!(
            url,
            "https://fe80--1s3.scoped.linko.internal:48855/v1/node/handshake"
        );
    }

    #[test]
    fn test_build_url_http() {
        let url = TargetUrl {
            version: ApiVersion::V2,
            protocol: "http",
            host: "192.168.1.1".to_string(),
            port: 48855,
            path: "/info",
            params: &[],
        }
        .to_string();
        assert_eq!(url, "http://192.168.1.1:48855/v1/node/status");
    }
}
