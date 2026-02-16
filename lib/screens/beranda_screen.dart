import 'package:flutter/material.dart';
import '../models/news_article.dart';
import '../services/news_service.dart';
import 'news_detail_screen.dart';

class BerandaScreen extends StatefulWidget {
  const BerandaScreen({super.key});

  @override
  State<BerandaScreen> createState() => _BerandaScreenState();
}

class _BerandaScreenState extends State<BerandaScreen> {
  final NewsService _newsService = NewsService();
  bool _isLoading = false;
  String? _errorMessage;
  List<NewsArticle> _articles = [];

  // Pagination
  int _currentPage = 0;
  static const int _itemsPerPage = 6;

  int get _totalPages => (_articles.length / _itemsPerPage).ceil();

  List<NewsArticle> get _currentPageArticles {
    final start = _currentPage * _itemsPerPage;
    final end = (start + _itemsPerPage).clamp(0, _articles.length);
    if (start >= _articles.length) return [];
    return _articles.sublist(start, end);
  }

  @override
  void initState() {
    super.initState();
    _loadNews();
  }

  Future<void> _loadNews() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final items = await _newsService.fetchNews();

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (items.isEmpty) {
        _errorMessage = 'Belum ada berita tersedia.';
      }
      _articles = items;
      _currentPage = 0;
    });
  }

  void _goToPage(int page) {
    if (page >= 0 && page < _totalPages) {
      setState(() {
        _currentPage = page;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      body: RefreshIndicator(
        onRefresh: _loadNews,
        color: const Color(0xFF368b3a),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _buildAppBar(context),
            _buildSectionHeader(),
            _buildContentSliver(),
            if (!_isLoading && _errorMessage == null && _articles.isNotEmpty)
              _buildPagination(),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  SliverAppBar _buildAppBar(BuildContext context) {
    return SliverAppBar(
      backgroundColor: const Color(0xFF368b3a),
      foregroundColor: Colors.white,
      elevation: 0,
      pinned: true,
      floating: true,
      snap: true,
      expandedHeight: 220,
      automaticallyImplyLeading: false,
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final statusBarHeight = MediaQuery.of(context).padding.top;
          final maxHeight = constraints.maxHeight;
          final minHeight = kToolbarHeight + statusBarHeight;
          final progress = ((maxHeight - minHeight) / (220 - minHeight)).clamp(
            0.0,
            1.0,
          );

          return Stack(
            fit: StackFit.expand,
            children: [
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF368b3a), Color(0xFF2c6d2f)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              Positioned(
                top: statusBarHeight + 16,
                left: 16,
                right: 16,
                child: Opacity(
                  opacity: progress,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        'Edukasi Pengelolaan Sampah',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Temukan tips terbaru, langkah praktis, dan inspirasi hidup hijau setiap hari.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Opacity(
                  opacity: progress,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0x19368b3a),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.auto_graph,
                            color: Color(0xFF368b3a),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Konten Edukatif',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1F2A1C),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _articles.isEmpty
                                    ? 'Tarik ke bawah untuk memperbarui berita.'
                                    : '${_articles.length} artikel terbaru siap dibaca.',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF5C6F5D),
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: _loadNews,
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF368b3a),
                          ),
                          child: const Text('Segarkan'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomLeft,
                child: Container(
                  height: kToolbarHeight + statusBarHeight,
                  padding: const EdgeInsetsDirectional.only(
                    start: 16,
                    bottom: 12,
                  ),
                  alignment: Alignment.bottomLeft,
                  child: Text(
                    'Beranda',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withOpacity(1 - progress * 0.6),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  SliverToBoxAdapter _buildSectionHeader() {
    return const SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 20, 16, 12),
        child: Row(
          children: [
            Icon(Icons.auto_awesome, color: Color(0xFF368b3a)),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Berita & Artikel Terbaru',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentSliver() {
    if (_isLoading) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(_errorMessage!, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loadNews,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF368b3a),
                foregroundColor: Colors.white,
              ),
              child: const Text('Muat Ulang'),
            ),
          ],
        ),
      );
    }

    final pageArticles = _currentPageArticles;

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.72,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          final article = pageArticles[index];
          return _NewsGridCard(
            article: article,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => NewsDetailScreen(slug: article.slug),
                ),
              );
            },
          );
        }, childCount: pageArticles.length),
      ),
    );
  }

  SliverToBoxAdapter _buildPagination() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Previous button
            Material(
              color: _currentPage > 0
                  ? const Color(0xFF368b3a)
                  : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: _currentPage > 0
                    ? () => _goToPage(_currentPage - 1)
                    : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.chevron_left,
                        size: 20,
                        color: _currentPage > 0 ? Colors.white : Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Prev',
                        style: TextStyle(
                          color: _currentPage > 0 ? Colors.white : Colors.grey,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Page indicators
            ...List.generate(_totalPages, (index) {
              final isActive = index == _currentPage;
              return GestureDetector(
                onTap: () => _goToPage(index),
                child: Container(
                  width: 36,
                  height: 36,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFF368b3a)
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: const Color(0xFF368b3a).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.grey.shade600,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              );
            }),

            const SizedBox(width: 12),

            // Next button
            Material(
              color: _currentPage < _totalPages - 1
                  ? const Color(0xFF368b3a)
                  : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: _currentPage < _totalPages - 1
                    ? () => _goToPage(_currentPage + 1)
                    : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Next',
                        style: TextStyle(
                          color: _currentPage < _totalPages - 1
                              ? Colors.white
                              : Colors.grey,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.chevron_right,
                        size: 20,
                        color: _currentPage < _totalPages - 1
                            ? Colors.white
                            : Colors.grey,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NewsGridCard extends StatelessWidget {
  final NewsArticle article;
  final VoidCallback onTap;

  const _NewsGridCard({required this.article, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(16),
      shadowColor: Colors.black12,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              Expanded(
                flex: 3,
                child: Hero(
                  tag: 'news-image-${article.slug}',
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: article.imageUrl.isNotEmpty
                        ? Image.network(
                            article.imageUrl,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.grey.shade200,
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.image_not_supported,
                                size: 32,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : Container(
                            color: Colors.grey.shade200,
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.image,
                              size: 32,
                              color: Colors.grey,
                            ),
                          ),
                  ),
                ),
              ),

              // Content
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0x19368b3a),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          article.category,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF368b3a),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Title
                      Expanded(
                        child: Text(
                          article.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1F2A1C),
                            height: 1.3,
                          ),
                        ),
                      ),

                      // Date
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            size: 11,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(article.createdAt),
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
