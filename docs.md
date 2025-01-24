## serviceDefs

Concrete service definitions, as per submodule options\.
Please put service-related options into ` services ` instead, and use this to implement them\.



*Type:*
attribute set of (submodule)

*Declared by:*
 - [ides\.nix](https://git.atagen.co/atagen/ides/ides.nix)



## serviceDefs\.\<name>\.args



Arguments to supply to the service binary\. Writing %CFG% in this will template to your config location\.



*Type:*
string



*Default:*
` "" `



*Example:*
` "run -c %CFG% --adapter caddyfile" `

*Declared by:*
 - [ides\.nix](https://git.atagen.co/atagen/ides/ides.nix)



## serviceDefs\.\<name>\.config



Options for setting the service’s configuration\.



*Type:*
submodule



*Default:*
` { } `

*Declared by:*
 - [ides\.nix](https://git.atagen.co/atagen/ides/ides.nix)



## serviceDefs\.\<name>\.config\.content



Attributes that define your config values\.



*Type:*
null or (attribute set)



*Default:*
` null `



*Example:*

```
{
  this = "that";
}
```

*Declared by:*
 - [ides\.nix](https://git.atagen.co/atagen/ides/ides.nix)



## serviceDefs\.\<name>\.config\.ext



If your service config requires a file extension, set it here\. This overrides ` format `’s output path’\.



*Type:*
string



*Default:*
` "" `



*Example:*
` "json" `

*Declared by:*
 - [ides\.nix](https://git.atagen.co/atagen/ides/ides.nix)



## serviceDefs\.\<name>\.config\.file



Path to config file\. This overrides all other values\.



*Type:*
null or path



*Default:*
` null `



*Example:*
` /home/bolt/code/ides/configs/my-config.ini `

*Declared by:*
 - [ides\.nix](https://git.atagen.co/atagen/ides/ides.nix)



## serviceDefs\.\<name>\.config\.format



Config output format\.
One of:
` java json yaml toml ini xml php `\.



*Type:*
null or one of “java”, “json”, “yaml”, “toml”, “ini”, “xml”, “php”



*Default:*
` null `



*Example:*
` "json" `

*Declared by:*
 - [ides\.nix](https://git.atagen.co/atagen/ides/ides.nix)



## serviceDefs\.\<name>\.config\.formatter



Serialisation/writer function to apply to ` content `\.
` format ` will auto-apply the correct format if the option value is valid\.
Should take ` path: attrs: ` and return a storepath\.



*Type:*
anything



*Default:*
` null `



*Example:*
` "pkgs.formats.yaml {}.generate" `

*Declared by:*
 - [ides\.nix](https://git.atagen.co/atagen/ides/ides.nix)



## serviceDefs\.\<name>\.config\.text



Plaintext configuration to use\.



*Type:*
string



*Default:*
` "" `



*Example:*

```
''
  http://*:8080 {
    respond "hello"
  }
''
```

*Declared by:*
 - [ides\.nix](https://git.atagen.co/atagen/ides/ides.nix)



## serviceDefs\.\<name>\.exec



Alternative executable name to use from ` pkg `\.



*Type:*
string



*Default:*
` "" `



*Example:*
` "caddy" `

*Declared by:*
 - [ides\.nix](https://git.atagen.co/atagen/ides/ides.nix)



## serviceDefs\.\<name>\.pkg



Package to use for service\.



*Type:*
package



*Example:*
` "pkgs.caddy" `

*Declared by:*
 - [ides\.nix](https://git.atagen.co/atagen/ides/ides.nix)



## services\.redis\.enable



Whether to enable Enable Redis…



*Type:*
boolean



*Default:*
` false `



*Example:*
` true `

*Declared by:*
 - [modules/redis\.nix](https://git.atagen.co/atagen/ides/modules/redis.nix)



## services\.redis\.bind



List of IPs to bind to\.



*Type:*
list of string



*Default:*

```
[
  "127.0.0.1"
  "::1"
]
```

*Declared by:*
 - [modules/redis\.nix](https://git.atagen.co/atagen/ides/modules/redis.nix)



## services\.redis\.databases



Number of databases\.



*Type:*
signed integer



*Default:*
` 16 `

*Declared by:*
 - [modules/redis\.nix](https://git.atagen.co/atagen/ides/modules/redis.nix)



## services\.redis\.extraConfig



Additional config directives\.



*Type:*
string



*Default:*
` "" `

*Declared by:*
 - [modules/redis\.nix](https://git.atagen.co/atagen/ides/modules/redis.nix)



## services\.redis\.logLevel



Logging verbosity level\.



*Type:*
one of “debug”, “verbose”, “notice”, “warning”, “nothing”



*Default:*
` "notice" `

*Declared by:*
 - [modules/redis\.nix](https://git.atagen.co/atagen/ides/modules/redis.nix)



## services\.redis\.port



Port to bind to\.



*Type:*
integer between 1024 and 65535 (both inclusive)



*Default:*
` 6379 `

*Declared by:*
 - [modules/redis\.nix](https://git.atagen.co/atagen/ides/modules/redis.nix)



## services\.redis\.socket



Unix socket to bind to\.



*Type:*
null or string



*Default:*
` null `

*Declared by:*
 - [modules/redis\.nix](https://git.atagen.co/atagen/ides/modules/redis.nix)



## services\.redis\.socketPerms



Permissions for the unix socket\.



*Type:*
null or signed integer



*Default:*
` null `

*Declared by:*
 - [modules/redis\.nix](https://git.atagen.co/atagen/ides/modules/redis.nix)


