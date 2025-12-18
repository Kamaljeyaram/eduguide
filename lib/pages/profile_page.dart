import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AuthService _authService = AuthService();
  bool _isDarkMode = false;
  bool _notificationsEnabled = true;
  String _selectedLanguage = 'English';

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // User Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                   CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.blue.shade100,
                    child: Text(
                      user?.email?.substring(0, 1).toUpperCase() ?? 'U',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                         Text(
                          user?.displayName ?? 'User',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          user?.email ?? 'No email',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Academic Details
            _buildSectionHeader('Academic Details'),
            _buildProfileCard(
              children: [
                _buildInfoRow(Icons.school, 'School/College', 'Greenwood High'),
                const Divider(),
                _buildInfoRow(Icons.grade, 'Grade/Standard', '12th Grade'),
                const Divider(),
                _buildInfoRow(Icons.book, 'Stream/Board', 'CBSE - Science'),
              ],
            ),
             const SizedBox(height: 24),

            // App Settings
            _buildSectionHeader('App Settings'),
            _buildProfileCard(
              children: [
                _buildSwitchRow(Icons.dark_mode, 'Dark Mode', _isDarkMode, (val) {
                  setState(() => _isDarkMode = val);
                }),
                const Divider(),
                _buildSwitchRow(Icons.notifications, 'Notifications', _notificationsEnabled, (val) {
                  setState(() => _notificationsEnabled = val);
                }),
                 const Divider(),
                _buildDropdownRow(Icons.language, 'Language', _selectedLanguage, ['English', 'Spanish', 'Hindi'], (val) {
                  setState(() => _selectedLanguage = val!);
                }),
              ],
            ),
             const SizedBox(height: 24),

            // Support & Info
            _buildSectionHeader('Support & Info'),
             _buildProfileCard(
              children: [
                _buildActionRow(Icons.help, 'Help Center', () {}), 
                 const Divider(),
                _buildActionRow(Icons.privacy_tip, 'Privacy Policy', () {}), 
                 const Divider(),
                _buildActionRow(Icons.info, 'About App', () {
                  showAboutDialog(
                    context: context,
                    applicationName: 'EduGuide',
                    applicationVersion: '1.0.0',
                    applicationIcon: const Icon(Icons.school, size: 50, color: Colors.blue),
                    children: [
                      const Text('EduGuide is your companion for academic success.'),
                    ],
                  );
                }),
              ],
            ),
            const SizedBox(height: 30),

            // Logout Button
             SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () async {
                  await _authService.signOut();
                  if (mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const LoginPage()),
                      (route) => false,
                    );
                  }
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: Colors.red),
                  foregroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Log Out'),
              ),
            ),
            const SizedBox(height: 20),
            const Center(
              child: Text(
                'Version 1.0.0',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
         boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueGrey, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 15)),
          ),
          Text(value, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildSwitchRow(IconData icon, String label, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueGrey, size: 20),
          const SizedBox(width: 16),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 15))),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _buildDropdownRow(IconData icon, String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueGrey, size: 20),
          const SizedBox(width: 16),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 15))),
          DropdownButton<String>(
            value: value,
            underline: const SizedBox(),
            items: items.map((String val) {
              return DropdownMenuItem<String>(
                value: val,
                child: Text(val),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

   Widget _buildActionRow(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, color: Colors.blueGrey, size: 20),
            const SizedBox(width: 16),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 15))),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
