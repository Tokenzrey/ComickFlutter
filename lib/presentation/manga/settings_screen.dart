import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../core/network/api_client.dart';
import '../../core/network/cloudflare/proxy_handler.dart';
import '../../core/network/doh_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ApiClient _apiClient = GetIt.instance<ApiClient>();

  // Settings state
  bool _isCloudflareDebugEnabled = false;
  bool _isCloudflareProtectionEnabled = true;
  bool _isProxyEnabled = false;
  bool _isDohEnabled = true;
  bool _isSslBypassEnabled = true;
  DoHProviderType _dohProviderType = DoHProviderType.cloudflare;
  CloudflareDoHProfile _cloudflareProfile = CloudflareDoHProfile.standard;

  // Cloudflare stats
  Map<String, dynamic> _cloudflareStats = {};

  // Proxy settings
  final TextEditingController _proxyHostController = TextEditingController();
  final TextEditingController _proxyPortController = TextEditingController();
  final TextEditingController _proxySchemeController =
      TextEditingController(text: 'http');

  // DoH status
  Map<String, String> _dohStatus = {};
  bool _isLoadingDohStatus = false;

  @override
  void initState() {
    super.initState();
    _loadAllSettings();
  }

  Future<void> _loadAllSettings() async {
    // Load settings from persistent storage
    await Future.wait([
      _loadCloudflareSettings(),
      _loadProxySettings(),
      _loadDohSettings(),
    ]);

    // Once settings are loaded, refresh the UI if the widget is still mounted
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadCloudflareSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get Cloudflare stats from API client
      final stats = _apiClient.getCloudflareStats();

      if (mounted) {
        setState(() {
          _cloudflareStats = stats;
          _isCloudflareDebugEnabled =
              prefs.getBool('cloudflare_debug_mode') ?? false;
          _isCloudflareProtectionEnabled =
              prefs.getBool('cf_protection_enabled') ?? true;
        });
      }
    } catch (e) {
      debugPrint('Error loading Cloudflare settings: $e');
    }
  }

  Future<void> _loadProxySettings() async {
    try {
      final proxyHandler = GetIt.instance<ProxyHandler>();
      final isEnabled = proxyHandler.isEnabled;
      final config = proxyHandler.config;

      if (mounted) {
        setState(() {
          _isProxyEnabled = isEnabled;
          if (config != null) {
            _proxyHostController.text = config.host;
            _proxyPortController.text = config.port.toString();
            _proxySchemeController.text = config.scheme;
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading proxy settings: $e');
    }
  }

  Future<void> _loadDohSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          _isDohEnabled = prefs.getBool('doh_enabled') ?? true;
          _isSslBypassEnabled = prefs.getBool('ssl_bypass_enabled') ?? false;

          // Load DoH provider type
          final providerIndex = prefs.getInt('doh_provider_type') ??
              DoHProviderType.cloudflare.index;
          _dohProviderType = DoHProviderType.values[providerIndex];

          // Load Cloudflare profile if applicable
          final profileIndex = prefs.getInt('cloudflare_doh_profile') ??
              CloudflareDoHProfile.standard.index;
          _cloudflareProfile = CloudflareDoHProfile.values[profileIndex];
        });
      }
    } catch (e) {
      debugPrint('Error loading DoH settings: $e');
    }
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (value is bool) {
        await prefs.setBool(key, value);
      } else if (value is int) {
        await prefs.setInt(key, value);
      } else if (value is String) {
        await prefs.setString(key, value);
      }
    } catch (e) {
      debugPrint('Error saving setting $key: $e');
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error saving settings: $e')));
      }
    }
  }

  Future<void> _loadDohStatus() async {
    if (_isLoadingDohStatus) return;

    setState(() {
      _isLoadingDohStatus = true;
    });

    try {
      final status = await _apiClient.getDohStatus();
      if (mounted) {
        setState(() {
          _dohStatus = status;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading DoH status: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingDohStatus = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // DoH settings card
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Network Security',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SwitchListTile(
                  title: const Text('DNS over HTTPS'),
                  subtitle:
                      const Text('Use encrypted DNS to prevent DNS blocking'),
                  value: _isDohEnabled,
                  onChanged: (value) async {
                    // Capture context before async operation
                    final scaffoldMessenger = ScaffoldMessenger.of(context);

                    setState(() {
                      _isDohEnabled = value;
                    });

                    await _saveSetting('doh_enabled', value);

                    if (mounted) {
                      scaffoldMessenger.showSnackBar(const SnackBar(
                          content: Text(
                              'Restart required for changes to take effect')));
                    }
                  },
                ),
                if (_isDohEnabled)
                  ListTile(
                    title: const Text('DoH Provider'),
                    subtitle: const Text('Choose DNS provider'),
                    trailing: DropdownButton<DoHProviderType>(
                      value: _dohProviderType,
                      onChanged: (DoHProviderType? newValue) async {
                        if (newValue != null) {
                          // Capture context before async operation
                          final scaffoldMessenger =
                              ScaffoldMessenger.of(context);

                          setState(() {
                            _dohProviderType = newValue;
                          });

                          await _saveSetting(
                              'doh_provider_type', newValue.index);
                          await _apiClient.updateDohProvider(newValue);

                          if (mounted) {
                            scaffoldMessenger.showSnackBar(const SnackBar(
                                content: Text(
                                    'Restart required for changes to take effect')));
                          }
                        }
                      },
                      items: DoHProviderType.values
                          .map<DropdownMenuItem<DoHProviderType>>(
                              (DoHProviderType type) {
                        String label;
                        switch (type) {
                          case DoHProviderType.none:
                            label = 'System DNS (No DoH)';
                            break;
                          case DoHProviderType.cloudflare:
                            label = 'Cloudflare DNS';
                            break;
                          case DoHProviderType.google:
                            label = 'Google DNS';
                            break;
                          case DoHProviderType.adguard:
                            label = 'Adguard DNS';
                            break;
                        }
                        return DropdownMenuItem<DoHProviderType>(
                          value: type,
                          child: Text(label),
                        );
                      }).toList(),
                    ),
                  ),

                // Show Cloudflare profile options only when Cloudflare is selected
                if (_isDohEnabled &&
                    _dohProviderType == DoHProviderType.cloudflare)
                  ListTile(
                    title: const Text('Cloudflare Profile'),
                    subtitle: const Text('Choose filtering level'),
                    trailing: DropdownButton<CloudflareDoHProfile>(
                      value: _cloudflareProfile,
                      onChanged: (CloudflareDoHProfile? newValue) async {
                        if (newValue != null) {
                          // Capture context before async operation
                          final scaffoldMessenger =
                              ScaffoldMessenger.of(context);

                          setState(() {
                            _cloudflareProfile = newValue;
                          });

                          await _saveSetting(
                              'cloudflare_doh_profile', newValue.index);

                          if (mounted) {
                            scaffoldMessenger.showSnackBar(const SnackBar(
                                content: Text(
                                    'Restart required for changes to take effect')));
                          }
                        }
                      },
                      items: CloudflareDoHProfile.values
                          .map<DropdownMenuItem<CloudflareDoHProfile>>(
                              (CloudflareDoHProfile profile) {
                        String label;
                        switch (profile) {
                          case CloudflareDoHProfile.standard:
                            label = 'Standard (No filtering)';
                            break;
                          case CloudflareDoHProfile.family:
                            label = 'Family (Blocks adult content)';
                            break;
                          case CloudflareDoHProfile.security:
                            label = 'Security (Blocks malware)';
                            break;
                        }
                        return DropdownMenuItem<CloudflareDoHProfile>(
                          value: profile,
                          child: Text(label),
                        );
                      }).toList(),
                    ),
                  ),

                SwitchListTile(
                  title: const Text('Bypass SSL Verification'),
                  subtitle: const Text(
                      'Allow connections to sites with invalid certificates'),
                  value: _isSslBypassEnabled,
                  onChanged: (value) async {
                    // Capture context before async operation
                    final scaffoldMessenger = ScaffoldMessenger.of(context);

                    setState(() {
                      _isSslBypassEnabled = value;
                    });

                    await _saveSetting('ssl_bypass_enabled', value);

                    if (mounted) {
                      scaffoldMessenger.showSnackBar(const SnackBar(
                          content: Text(
                              'Restart required for changes to take effect')));
                    }
                  },
                ),

                if (_isDohEnabled)
                  ListTile(
                    title: const Text('DNS Cache'),
                    subtitle: const Text('Clear DNS resolution cache'),
                    trailing: ElevatedButton(
                      onPressed: () async {
                        final scaffoldMessenger = ScaffoldMessenger.of(context);
                        await _apiClient.clearDohCache();
                        if (mounted) {
                          scaffoldMessenger.showSnackBar(const SnackBar(
                              content: Text('DNS cache cleared')));
                          // Reload status after clearing cache
                          _loadDohStatus();
                        }
                      },
                      child: const Text('Clear Cache'),
                    ),
                  ),

                if (_isDohEnabled)
                  ExpansionTile(
                    title: const Text('DNS Status'),
                    subtitle: const Text('View DNS resolutions'),
                    trailing: _isLoadingDohStatus
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : null,
                    onExpansionChanged: (expanded) {
                      if (expanded) {
                        _loadDohStatus();
                      }
                    },
                    children: [
                      if (_dohStatus.isEmpty && !_isLoadingDohStatus)
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                              'No DNS resolutions yet. Try browsing some content.'),
                        ),
                      if (_dohStatus.isNotEmpty &&
                          _dohStatus.containsKey('_provider'))
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 8.0),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Active Provider: ${_dohStatus['_provider'] ?? 'Unknown'}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer,
                              ),
                            ),
                          ),
                        ),
                      if (_dohStatus.isNotEmpty)
                        ListView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: _dohStatus.length,
                          itemBuilder: (context, index) {
                            final entry = _dohStatus.entries.elementAt(index);
                            // Skip the provider info as it's already shown above
                            if (entry.key == '_provider') {
                              return const SizedBox.shrink();
                            }
                            return ListTile(
                              dense: true,
                              title: Text(entry.key),
                              subtitle: Text(entry.value),
                            );
                          },
                        ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: ElevatedButton.icon(
                          onPressed:
                              _isLoadingDohStatus ? null : _loadDohStatus,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Refresh'),
                        ),
                      ),
                    ],
                  ),
                const Divider(),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Cloudflare protection card
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Cloudflare Protection',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // Enable/disable Cloudflare protection
                // Enable/disable Cloudflare protection
                SwitchListTile(
                  title: const Text('Enable Protection'),
                  subtitle:
                      const Text('Automatically handle Cloudflare challenges'),
                  value: _isCloudflareProtectionEnabled,
                  onChanged: (value) async {
                    // Capture the ScaffoldMessengerState before async operation
                    final scaffoldMessenger = ScaffoldMessenger.of(context);

                    setState(() {
                      _isCloudflareProtectionEnabled = value;
                    });

                    await _saveSetting('cf_protection_enabled', value);

                    // Use captured scaffoldMessenger after async gap
                    if (mounted) {
                      scaffoldMessenger.showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Restart required for changes to take effect')),
                      );
                    }
                  },
                ),

                SwitchListTile(
                  title: const Text('Debug Mode'),
                  subtitle: const Text(
                      'Show detailed logs and debug information for Cloudflare challenges'),
                  value: _isCloudflareDebugEnabled,
                  onChanged: (value) async {
                    setState(() {
                      _isCloudflareDebugEnabled = value;
                    });
                    _apiClient.setCloudflareDebugMode(value);
                    await _saveSetting('cloudflare_debug_mode', value);
                  },
                ),

                // Cloudflare stats
                if (_cloudflareStats.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Statistics',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                            'Challenges solved: ${_cloudflareStats['challengesSolved'] ?? 0}'),
                        if (_cloudflareStats['lastSolvedAt'] != null)
                          Text(
                              'Last solved: ${_cloudflareStats['lastSolvedAt']}'),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),

                ListTile(
                  title: const Text('Clear Cloudflare Data'),
                  subtitle:
                      const Text('Remove all stored cookies and session data'),
                  trailing: ElevatedButton(
                    onPressed: () async {
                      // Capture context before async operation
                      final scaffoldMessenger = ScaffoldMessenger.of(context);
                      await _apiClient.clearCloudflareData();

                      // Refresh stats after clearing
                      final stats = _apiClient.getCloudflareStats();
                      if (mounted) {
                        setState(() {
                          _cloudflareStats = stats;
                        });
                      }

                      if (mounted) {
                        scaffoldMessenger.showSnackBar(
                          const SnackBar(
                              content: Text('Cloudflare data cleared')),
                        );
                      }
                    },
                    child: const Text('Clear'),
                  ),
                ),

                ListTile(
                  title: const Text('Manually Solve Challenge'),
                  subtitle: const Text('Open interactive challenge solver'),
                  trailing: ElevatedButton.icon(
                    icon: const Icon(Icons.security),
                    onPressed: () async {
                      showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: const Text('Cloudflare Challenge'),
                            content: const Text(
                                'This will open a browser page to solve the Cloudflare '
                                'challenge manually. After solving, your access should '
                                'be restored.\n\nWant to continue?'),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () async {
                                  // Capture context before async operation
                                  final scaffoldMessenger =
                                      ScaffoldMessenger.of(context);
                                  Navigator.pop(context);

                                  final success = await _apiClient
                                      .solveInteractiveChallenge(
                                          'https://api.comick.io/v1.0/search?sort=user_follow_count&page=1');

                                  // Refresh stats after solving
                                  final stats = _apiClient.getCloudflareStats();
                                  if (mounted) {
                                    setState(() {
                                      _cloudflareStats = stats;
                                    });
                                  }

                                  if (mounted) {
                                    scaffoldMessenger.showSnackBar(
                                      SnackBar(
                                        content: Text(success
                                            ? 'Challenge solved successfully!'
                                            : 'Failed to solve challenge'),
                                        backgroundColor:
                                            success ? Colors.green : Colors.red,
                                      ),
                                    );
                                  }
                                },
                                child: const Text('Solve Challenge'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    label: const Text('Solve'),
                  ),
                ),

                // Test connection
                ListTile(
                  title: const Text('Test Connection'),
                  subtitle: const Text(
                      'Check if the API is accessible without challenges'),
                  trailing: ElevatedButton.icon(
                    icon: const Icon(Icons.network_check),
                    onPressed: () async {
                      // Capture BuildContext references before any async operations
                      final navigator = Navigator.of(context);
                      final scaffoldMessenger = ScaffoldMessenger.of(context);

                      // Show loading indicator
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => const Center(
                          child: CircularProgressIndicator(),
                        ),
                      );

                      try {
                        final success = await _apiClient.testCloudflareConnection(
                            'https://api.comick.io/v1.0/search?sort=user_follow_count&page=1');

                        // Pop loading dialog using the captured navigator
                        if (mounted) navigator.pop();

                        // Use the captured scaffoldMessenger for showing the SnackBar
                        if (mounted) {
                          scaffoldMessenger.showSnackBar(
                            SnackBar(
                              content: Text(success
                                  ? 'Connection successful! No challenge detected.'
                                  : 'Connection failed or challenge detected'),
                              backgroundColor:
                                  success ? Colors.green : Colors.orange,
                            ),
                          );
                        }
                      } catch (e) {
                        // Pop loading dialog using the captured navigator
                        if (mounted) navigator.pop();

                        // Use the captured scaffoldMessenger for showing the SnackBar
                        if (mounted) {
                          scaffoldMessenger.showSnackBar(
                            SnackBar(
                              content: Text('Connection error: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    label: const Text('Test'),
                  ),
                ),

                const Divider(),

                // Proxy settings section
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Proxy Settings',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SwitchListTile(
                  title: const Text('Enable Proxy'),
                  subtitle: const Text('Use a proxy for all API requests'),
                  value: _isProxyEnabled,
                  onChanged: (value) async {
                    setState(() {
                      _isProxyEnabled = value;
                    });

                    if (value &&
                        _proxyHostController.text.isNotEmpty &&
                        _proxyPortController.text.isNotEmpty) {
                      final port =
                          int.tryParse(_proxyPortController.text) ?? 8080;

                      final config = ProxyConfig(
                        scheme: _proxySchemeController.text.isEmpty
                            ? 'http'
                            : _proxySchemeController.text,
                        host: _proxyHostController.text,
                        port: port,
                      );

                      await _apiClient.updateProxySettings(
                        enabled: true,
                        config: config,
                      );
                    } else {
                      await _apiClient.updateProxySettings(
                        enabled: false,
                      );
                    }
                  },
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Scheme (http, https, socks5)
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Proxy Scheme',
                        ),
                        value: _proxySchemeController.text,
                        items: const [
                          DropdownMenuItem(value: 'http', child: Text('HTTP')),
                          DropdownMenuItem(
                              value: 'https', child: Text('HTTPS')),
                          DropdownMenuItem(
                              value: 'socks5', child: Text('SOCKS5')),
                        ],
                        onChanged: _isProxyEnabled
                            ? (value) {
                                if (value != null) {
                                  _proxySchemeController.text = value;
                                }
                              }
                            : null,
                      ),

                      const SizedBox(height: 16),
                      TextField(
                        controller: _proxyHostController,
                        decoration: const InputDecoration(
                          labelText: 'Proxy Host',
                          hintText: 'e.g., 192.168.1.1',
                        ),
                        enabled: _isProxyEnabled,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _proxyPortController,
                        decoration: const InputDecoration(
                          labelText: 'Proxy Port',
                          hintText: 'e.g., 8080',
                        ),
                        keyboardType: TextInputType.number,
                        enabled: _isProxyEnabled,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _isProxyEnabled
                            ? () async {
                                // Check input validation first
                                if (_proxyHostController.text.isEmpty ||
                                    _proxyPortController.text.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content:
                                            Text('Please enter host and port')),
                                  );
                                  return;
                                }

                                final port =
                                    int.tryParse(_proxyPortController.text);
                                if (port == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Please enter a valid port number')),
                                  );
                                  return;
                                }

                                // Capture context before async operation
                                final scaffoldMessenger =
                                    ScaffoldMessenger.of(context);

                                final config = ProxyConfig(
                                  scheme: _proxySchemeController.text.isEmpty
                                      ? 'http'
                                      : _proxySchemeController.text,
                                  host: _proxyHostController.text,
                                  port: port,
                                );

                                await _apiClient.updateProxySettings(
                                  enabled: true,
                                  config: config,
                                );

                                if (mounted) {
                                  scaffoldMessenger.showSnackBar(
                                    const SnackBar(
                                        content:
                                            Text('Proxy settings updated')),
                                  );
                                }
                              }
                            : null,
                        child: const Text('Save Proxy Settings'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // About card with updated description
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'About',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'This application includes advanced networking features for areas with restricted internet access:\n'
                    '• Cloudflare challenge solver (automatic & manual)\n'
                    '• Multiple DNS-over-HTTPS providers (Cloudflare, Google, Adguard)\n'
                    '• SSL certificate verification bypass\n'
                    '• HTTP/HTTPS/SOCKS5 proxy support',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Version 1.3.0 • Built: 2025-04-21',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _proxyHostController.dispose();
    _proxyPortController.dispose();
    _proxySchemeController.dispose();
    super.dispose();
  }
}
