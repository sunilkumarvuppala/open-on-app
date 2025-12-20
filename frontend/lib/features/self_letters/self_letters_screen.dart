import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openon_app/core/providers/providers.dart';
import 'package:openon_app/core/router/app_router.dart';
import 'package:openon_app/core/theme/app_theme.dart';
import 'package:openon_app/core/theme/dynamic_theme.dart';
import 'package:openon_app/core/models/models.dart';
import 'package:intl/intl.dart';

class SelfLettersScreen extends ConsumerStatefulWidget {
  const SelfLettersScreen({super.key});
  
  @override
  ConsumerState<SelfLettersScreen> createState() => _SelfLettersScreenState();
}

class _SelfLettersScreenState extends ConsumerState<SelfLettersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _onRefresh() async {
    ref.invalidate(selfLettersProvider);
  }
  
  @override
  Widget build(BuildContext context) {
    final lettersAsync = ref.watch(selfLettersProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Letters to Self'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push(Routes.createSelfLetter),
            tooltip: 'Write to future me',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Waiting'),
            Tab(text: 'Archive'),
          ],
        ),
      ),
      body: lettersAsync.when(
        data: (letters) {
          // OPTIMIZATION: Use efficient filtering - separate in single pass
          final waiting = <SelfLetter>[];
          final archive = <SelfLetter>[];
          
          for (final letter in letters) {
            if (letter.isOpened) {
              archive.add(letter);
            } else {
              waiting.add(letter);
            }
          }
          
          return TabBarView(
            controller: _tabController,
            children: [
              _WaitingTab(letters: waiting, onRefresh: _onRefresh),
              _ArchiveTab(letters: archive, onRefresh: _onRefresh),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48),
                const SizedBox(height: AppTheme.spacingMd),
                Text('Failed to load letters'),
                const SizedBox(height: AppTheme.spacingMd),
                TextButton(
                  onPressed: _onRefresh,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _WaitingTab extends ConsumerWidget {
  final List<SelfLetter> letters;
  final VoidCallback onRefresh;
  
  const _WaitingTab({required this.letters, required this.onRefresh});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (letters.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async => onRefresh(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.schedule,
                    size: 64,
                    color: DynamicTheme.getSecondaryTextColor(
                      ref.watch(selectedColorSchemeProvider),
                    ).withOpacity(0.5),
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  Text(
                    'No letters waiting',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  Text(
                    'Write a letter to your future self',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView.builder(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        itemCount: letters.length,
        itemBuilder: (context, index) {
          final letter = letters[index];
          return _SelfLetterCard(letter: letter);
        },
      ),
    );
  }
}

class _ArchiveTab extends ConsumerWidget {
  final List<SelfLetter> letters;
  final VoidCallback onRefresh;
  
  const _ArchiveTab({required this.letters, required this.onRefresh});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (letters.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async => onRefresh(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.archive,
                    size: 64,
                    color: DynamicTheme.getSecondaryTextColor(
                      ref.watch(selectedColorSchemeProvider),
                    ).withOpacity(0.5),
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  Text(
                    'No opened letters yet',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView.builder(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        itemCount: letters.length,
        itemBuilder: (context, index) {
          final letter = letters[index];
          return _SelfLetterCard(letter: letter, isOpened: true);
        },
      ),
    );
  }
}

class _SelfLetterCard extends ConsumerWidget {
  final SelfLetter letter;
  final bool isOpened;
  
  const _SelfLetterCard({
    required this.letter,
    this.isOpened = false,
  });
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = ref.watch(selectedColorSchemeProvider);
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      child: InkWell(
        onTap: () {
          if (letter.isOpenable) {
            context.push(Routes.openSelfLetter(letter.id));
          } else if (isOpened) {
            context.push(Routes.selfLetterDetail(letter.id));
          }
        },
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    isOpened ? Icons.mail_outline : Icons.schedule,
                    color: colorScheme.primary1,
                  ),
                  const SizedBox(width: AppTheme.spacingSm),
                  Expanded(
                    child: Text(
                      isOpened
                          ? 'Opened ${DateFormat('MMM d, y').format(letter.openedAt!)}'
                          : letter.timeUntilOpenText,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  if (letter.isOpenable)
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: DynamicTheme.getSecondaryTextColor(colorScheme).withOpacity(0.5),
                    ),
                ],
              ),
              
              const SizedBox(height: AppTheme.spacingSm),
              
              // Context
              if (letter.contextText.isNotEmpty)
                Text(
                  letter.contextText,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: DynamicTheme.getSecondaryTextColor(colorScheme).withOpacity(0.7),
                  ),
                ),
              
              // Content preview (only if opened)
              if (isOpened && letter.content != null) ...[
                const SizedBox(height: AppTheme.spacingMd),
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingMd),
                  decoration: BoxDecoration(
                    color: DynamicTheme.getSecondaryTextColor(colorScheme).withOpacity(0.05),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  child: Text(
                    letter.content!,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
              
              // Reflection indicator
              if (isOpened && letter.hasReflection) ...[
                const SizedBox(height: AppTheme.spacingSm),
                Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 16,
                      color: Colors.green,
                    ),
                    const SizedBox(width: AppTheme.spacingXs),
                    Text(
                      'Reflected',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
