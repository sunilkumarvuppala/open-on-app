import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openon_app/core/models/models.dart';
import 'package:openon_app/core/providers/providers.dart';
import 'package:openon_app/core/router/app_router.dart';
import 'package:openon_app/core/theme/app_theme.dart';

class StepChooseRecipient extends ConsumerStatefulWidget {
  final VoidCallback onNext;
  
  const StepChooseRecipient({super.key, required this.onNext});
  
  @override
  ConsumerState<StepChooseRecipient> createState() => _StepChooseRecipientState();
}

class _StepChooseRecipientState extends ConsumerState<StepChooseRecipient> {
  String _searchQuery = '';
  
  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final selectedRecipient = ref.watch(draftCapsuleProvider).recipient;
    
    return userAsync.when(
      data: (user) {
        if (user == null) return const SizedBox();
        
        final recipientsAsync = ref.watch(recipientsProvider(user.id));
        
        return recipientsAsync.when(
          data: (recipients) {
            final filteredRecipients = recipients.where((r) {
              if (_searchQuery.isEmpty) return true;
              return r.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                  r.relationship.toLowerCase().contains(_searchQuery.toLowerCase());
            }).toList();
            
            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Who is this letter for?',
                          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Choose someone special to receive your letter',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: AppColors.gray,
                              ),
                        ),
                        const SizedBox(height: 32),
                        
                        // Search field
                        TextField(
                          decoration: InputDecoration(
                            hintText: 'Search recipients...',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      setState(() => _searchQuery = '');
                                    },
                                  )
                                : null,
                          ),
                          onChanged: (value) {
                            setState(() => _searchQuery = value);
                          },
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Add new recipient button
                        Card(
                          child: InkWell(
                            onTap: () async {
                              await context.push(Routes.addRecipient);
                              ref.invalidate(recipientsProvider);
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      color: AppColors.deepPurple.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.add,
                                      color: AppColors.deepPurple,
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Add New Recipient',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'Create a new person to send letters to',
                                          style: TextStyle(
                                            color: AppColors.gray,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right, color: AppColors.gray),
                                ],
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Recipients list
                        if (filteredRecipients.isEmpty) ...[
                          const SizedBox(height: 32),
                          Center(
                            child: Text(
                              _searchQuery.isEmpty
                                  ? 'No recipients yet'
                                  : 'No recipients found',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: AppColors.gray,
                                  ),
                            ),
                          ),
                        ] else
                          ...filteredRecipients.map((recipient) {
                            final isSelected = selectedRecipient?.id == recipient.id;
                            
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              color: isSelected
                                  ? AppColors.deepPurple.withOpacity(0.1)
                                  : null,
                              child: InkWell(
                                onTap: () {
                                  ref.read(draftCapsuleProvider.notifier)
                                      .setRecipient(recipient);
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 28,
                                        backgroundColor: isSelected
                                            ? AppColors.deepPurple
                                            : AppColors.deepPurple.withOpacity(0.1),
                                        child: Text(
                                          recipient.name[0].toUpperCase(),
                                          style: TextStyle(
                                            color: isSelected
                                                ? AppColors.white
                                                : AppColors.deepPurple,
                                            fontSize: 20,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              recipient.name,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              recipient.relationship,
                                              style: const TextStyle(
                                                color: AppColors.gray,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (isSelected)
                                        const Icon(
                                          Icons.check_circle,
                                          color: AppColors.deepPurple,
                                          size: 28,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                ),
                
                // Next button
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: selectedRecipient != null ? widget.onNext : null,
                      child: const Text('Continue'),
                    ),
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Error: $error')),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }
}
