import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
    final colorScheme = ref.watch(selectedColorSchemeProvider);
    
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
                    padding: EdgeInsets.all(AppTheme.spacingLg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Who is this letter for?',
                          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: colorScheme.id == 'deep_blue' ? Colors.white : AppColors.textDark,
                              ),
                        ),
                        SizedBox(height: AppTheme.spacingSm),
                        Text(
                          'Choose someone special to receive your letter',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: colorScheme.id == 'deep_blue' 
                                    ? Colors.white.withOpacity(0.9) 
                                    : AppTheme.textGrey,
                              ),
                        ),
                        SizedBox(height: AppTheme.spacingXl),
                        
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
                        
                        SizedBox(height: AppTheme.spacingLg),
                        
                        // Recipients list
                        if (filteredRecipients.isEmpty) ...[
                          SizedBox(height: AppTheme.spacingXl),
                          Center(
                            child: Text(
                              _searchQuery.isEmpty
                                  ? 'No recipients yet'
                                  : 'No recipients found',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: colorScheme.id == 'deep_blue' 
                                        ? Colors.white.withOpacity(0.9) 
                                        : AppTheme.textGrey,
                                  ),
                            ),
                          ),
                        ] else
                          ...filteredRecipients.map((recipient) {
                            final isSelected = selectedRecipient?.id == recipient.id;
                            
                            return Padding(
                              padding: EdgeInsets.only(bottom: AppTheme.spacingMd),
                              child: Card(
                                elevation: 2,
                                margin: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                                ),
                                color: isSelected
                                    ? colorScheme.primary1.withOpacity(0.1)
                                    : null,
                                child: InkWell(
                                  onTap: () {
                                    ref.read(draftCapsuleProvider.notifier)
                                        .setRecipient(recipient);
                                  },
                                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                                  child: Padding(
                                    padding: EdgeInsets.all(AppTheme.spacingMd),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 28,
                                          backgroundColor: isSelected
                                              ? colorScheme.primary1
                                              : colorScheme.primary1.withOpacity(0.1),
                                          child: Text(
                                            recipient.name[0].toUpperCase(),
                                            style: TextStyle(
                                              color: isSelected
                                                  ? AppColors.white
                                                  : colorScheme.primary1,
                                              fontSize: 20,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: AppTheme.spacingMd),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                recipient.name,
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  color: colorScheme.id == 'deep_blue' 
                                                      ? Colors.white 
                                                      : AppColors.textDark,
                                                ),
                                              ),
                                              SizedBox(height: AppTheme.spacingXs),
                                              Text(
                                                recipient.relationship,
                                                style: TextStyle(
                                                  color: colorScheme.id == 'deep_blue' 
                                                      ? Colors.white.withOpacity(0.8) 
                                                      : AppTheme.textGrey,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (isSelected)
                                          Icon(
                                            Icons.check_circle,
                                            color: colorScheme.primary1,
                                            size: 28,
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        
                        SizedBox(height: AppTheme.spacingLg),
                        
                        // Add new recipient button at bottom
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                          ),
                          child: InkWell(
                            onTap: () async {
                              await context.push(Routes.addRecipient);
                              ref.invalidate(recipientsProvider(user.id));
                            },
                            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                            child: Padding(
                              padding: EdgeInsets.all(AppTheme.spacingMd),
                              child: Row(
                                children: [
                                  Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      color: colorScheme.primary1.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.add,
                                      color: colorScheme.primary1,
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Add New Recipient',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: colorScheme.id == 'deep_blue' 
                                                ? Colors.white 
                                                : AppColors.textDark,
                                          ),
                                        ),
                                        SizedBox(height: AppTheme.spacingXs),
                                        Text(
                                          'Create a new person to send letters to',
                                          style: TextStyle(
                                            color: colorScheme.id == 'deep_blue' 
                                                ? Colors.white.withOpacity(0.8) 
                                                : AppTheme.textGrey,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right,
                                    color: colorScheme.id == 'deep_blue' 
                                        ? Colors.white.withOpacity(0.7) 
                                        : AppTheme.textGrey,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Next button
                Container(
                  padding: EdgeInsets.all(AppTheme.spacingLg),
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary1,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                        ),
                      ),
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
