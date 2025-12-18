import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'chat_page.dart';
import 'practice_page.dart';
import 'predict_page.dart';
import 'profile_page.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  void _showFeatureDialog(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTryNow,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [color.withOpacity(0.05), Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(icon, color: color, size: 40),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D2D2D),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          onTryNow();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: color,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: const Text(
                          'Try Now',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final user = authService.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Stack(
        children: [
          // Background decoration
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFFB5A7).withOpacity(0.2),
              ),
            ),
          ),
          Positioned(
            top: 100,
            left: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFF9B8A).withOpacity(0.15),
              ),
            ),
          ),

          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        // Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hello, ${user?.displayName?.split(' ')[0] ?? 'Student'}! 👋',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF2D2D2D),
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Let\'s shape your future today.',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const ProfilePage(),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFFFFB5A7),
                                    width: 2,
                                  ),
                                ),
                                child: CircleAvatar(
                                  backgroundColor: const Color(0xFFFFE5E0),
                                  radius: 22,
                                  child: const Icon(
                                    Icons.person,
                                    color: Color(0xFFFF6B6B),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Banner Carousel
                        SizedBox(
                          height: 180,
                          child: PageView(
                            children: [
                              _buildBannerCard(
                                title: 'Daily Motivation',
                                content:
                                    '"The only way to predict the future is to create it."',
                                subtitles: '- Abraham Lincoln',
                                color1: const Color(0xFFFFB5A7),
                                color2: const Color(0xFFFF8A80),
                              ),
                              _buildBannerCard(
                                title: 'TNEA Updates',
                                content:
                                    'Counselling dates expected to be announced soon.',
                                subtitles: 'Stay tuned!',
                                color1: const Color(0xFF81D4FA),
                                color2: const Color(0xFF29B6F6),
                              ),
                              _buildBannerCard(
                                title: 'Pro Tip',
                                content:
                                    'Solve at least 20 physics problems today.',
                                subtitles: 'Consistency is key.',
                                color1: const Color(0xFFA5D6A7),
                                color2: const Color(0xFF66BB6A),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Features Grid Label
                        Text(
                          'Explore',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF2D2D2D),
                              ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),

                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  sliver: SliverGrid.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.85,
                    children: [
                      _ModernDashboardCard(
                        title: 'Counselling',
                        subtitle: 'Expert Guidance',
                        icon: Icons.school_rounded,
                        color: const Color(0xFF7E57C2), // Deep Purple
                        onTap: () {
                          _showFeatureDialog(
                            context,
                            title: 'Counselling & Career Guidance',
                            description:
                                'Get expert advice on college admissions, course selection, and career planning. Our counsellors help you make informed decisions about your academic future.',
                            icon: Icons.school_rounded,
                            color: const Color(0xFF7E57C2),
                            onTryNow: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ChatPage(),
                                ),
                              );
                            },
                          );
                        },
                      ),
                      _ModernDashboardCard(
                        title: 'Marks Analysis',
                        subtitle: 'Track Growth',
                        icon: Icons.bar_chart_rounded,
                        color: const Color(0xFF26A69A), // Teal
                        onTap: () {
                          _showFeatureDialog(
                            context,
                            title: 'Marks Analysis & Prediction',
                            description:
                                'Analyze your academic performance with detailed insights and predictions. Track your progress and get personalized recommendations for improvement.',
                            icon: Icons.bar_chart_rounded,
                            color: const Color(0xFF26A69A),
                            onTryNow: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const PredictPage(),
                                ),
                              );
                            },
                          );
                        },
                      ),
                      _ModernDashboardCard(
                        title: 'Question Banks',
                        subtitle: 'Practice Papers',
                        icon: Icons.library_books_rounded,
                        color: const Color(0xFFFFA726), // Orange
                        onTap: () {
                          _showFeatureDialog(
                            context,
                            title: 'Question Banks & Practice Papers',
                            description:
                                'Access thousands of practice questions, previous year papers, and subject-wise question banks to enhance your preparation and boost confidence.',
                            icon: Icons.library_books_rounded,
                            color: const Color(0xFFFFA726),
                            onTryNow: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const PracticePage(),
                                ),
                              );
                            },
                          );
                        },
                      ),
                      _ModernDashboardCard(
                        title: 'Quizzes',
                        subtitle: 'Test Yourself',
                        icon: Icons.quiz_rounded,
                        color: const Color(0xFFEF5350), // Red
                        onTap: () {
                          _showFeatureDialog(
                            context,
                            title: 'Interactive Quizzes & Tests',
                            description:
                                'Challenge yourself with interactive quizzes, mock tests, and timed assessments. Get instant feedback and improve your knowledge across all subjects.',
                            icon: Icons.quiz_rounded,
                            color: const Color(0xFFEF5350),
                            onTryNow: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const PracticePage(),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 30)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerCard({
    required String title,
    required String content,
    required String subtitles,
    required Color color1,
    required Color color2,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color1, color2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color2.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            content,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              height: 1.4,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            subtitles,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModernDashboardCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ModernDashboardCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const Spacer(),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF2D2D2D),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
