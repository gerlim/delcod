import 'package:barcode_app/app/shell/shell_primitives.dart';
import 'package:barcode_app/app/theme/app_colors.dart';
import 'package:barcode_app/features/auth/application/current_session_provider.dart';
import 'package:barcode_app/features/collections/application/collections_controller.dart';
import 'package:barcode_app/features/collections/data/collections_repository.dart';
import 'package:barcode_app/features/collections/domain/collection_status.dart';
import 'package:barcode_app/features/sync/presentation/sync_status_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CollectionsPage extends ConsumerStatefulWidget {
  const CollectionsPage({
    super.key,
    this.onOpenCollection,
  });

  final Future<void> Function(CollectionItem collection)? onOpenCollection;

  @override
  ConsumerState<CollectionsPage> createState() => _CollectionsPageState();
}

class _CollectionsPageState extends ConsumerState<CollectionsPage> {
  Future<void> _showCreateCollectionDialog() async {
    final controller = TextEditingController();
    var shouldWarnAboutCompany = false;

    final createdCollection = await showDialog<CollectionItem>(
      context: context,
      builder: (dialogContext) {
        final navigator = Navigator.of(dialogContext);
        return AlertDialog(
          title: const Text('Nova coleta'),
          content: TextFormField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Nome da coleta',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => navigator.pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () async {
                final session = ref.read(currentSessionProvider);
                final title = controller.text.trim();
                if (session == null || session.activeCompanyId == null) {
                  shouldWarnAboutCompany = true;
                  navigator.pop();
                  return;
                }

                if (title.isEmpty) {
                  return;
                }

                final collection = await ref
                    .read(collectionsControllerProvider.notifier)
                    .createCollection(
                      title: title,
                      companyId: session.activeCompanyId!,
                      createdBy: session.userId,
                    );

                if (!mounted) {
                  return;
                }

                navigator.pop(collection);
              },
              child: const Text('Criar coleta'),
            ),
          ],
        );
      },
    );
    if (!mounted) {
      return;
    }

    if (shouldWarnAboutCompany) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione uma empresa antes de criar a coleta'),
        ),
      );
      return;
    }

    if (createdCollection != null) {
      await _openCollection(createdCollection);
    }
  }

  Future<void> _openCollection(CollectionItem collection) async {
    if (widget.onOpenCollection case final callback?) {
      await callback(collection);
      return;
    }

    if (!mounted) {
      return;
    }

    context.go('/collections/${collection.id}', extra: collection);
  }

  @override
  Widget build(BuildContext context) {
    final collections = ref.watch(collectionsControllerProvider);
    final compact = MediaQuery.sizeOf(context).width < 680;
    final items = collections.valueOrNull ?? const <CollectionItem>[];
    final openCount =
        items.where((item) => item.status == CollectionStatus.open).length;
    final closedCount =
        items.where((item) => item.status == CollectionStatus.closed).length;
    final syncingCount =
        items.where((item) => item.status == CollectionStatus.syncing).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Coletas',
          subtitle:
              'Organize os lotes de leitura por empresa e acompanhe o progresso operacional.',
          actions: [
            FilledButton.icon(
              onPressed: _showCreateCollectionDialog,
              icon: const Icon(Icons.add),
              label: const Text('Nova coleta'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const SyncStatusBanner(),
        const SizedBox(height: 20),
        if (compact)
          SizedBox(
            height: 146,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                SizedBox(
                  width: 220,
                  child: MetricCard(
                    label: 'Coletas abertas',
                    value: '$openCount',
                    icon: Icons.folder_open_outlined,
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 220,
                  child: MetricCard(
                    label: 'Coletas fechadas',
                    value: '$closedCount',
                    icon: Icons.inventory_outlined,
                    emphasisColor: AppColors.safeGreen,
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 220,
                  child: MetricCard(
                    label: 'Pendentes de sync',
                    value: '$syncingCount',
                    icon: Icons.sync_outlined,
                    emphasisColor: AppColors.alertAmber,
                  ),
                ),
              ],
            ),
          )
        else
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              SizedBox(
                width: 220,
                child: MetricCard(
                  label: 'Coletas abertas',
                  value: '$openCount',
                  icon: Icons.folder_open_outlined,
                ),
              ),
              SizedBox(
                width: 220,
                child: MetricCard(
                  label: 'Coletas fechadas',
                  value: '$closedCount',
                  icon: Icons.inventory_outlined,
                  emphasisColor: AppColors.safeGreen,
                ),
              ),
              SizedBox(
                width: 220,
                child: MetricCard(
                  label: 'Pendentes de sync',
                  value: '$syncingCount',
                  icon: Icons.sync_outlined,
                  emphasisColor: AppColors.alertAmber,
                ),
              ),
            ],
          ),
        const SizedBox(height: 20),
        Expanded(
          child: SectionCard(
            padding: EdgeInsets.zero,
            child: collections.when(
              data: (items) {
                if (items.isEmpty) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.inbox_outlined,
                            size: 40,
                            color: AppColors.steel,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Nenhuma coleta criada',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Crie a primeira coleta para iniciar as leituras desta empresa.',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: AppColors.steel,
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => _openCollection(item),
                      child: Ink(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: AppColors.paper,
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 6,
                              height: 112,
                              decoration: BoxDecoration(
                                color: _statusColor(item.status),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(20),
                                  bottomLeft: Radius.circular(20),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(18),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Wrap(
                                      spacing: 12,
                                      runSpacing: 12,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      children: [
                                        Text(
                                          item.title,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                        StatusChip(
                                          label: _statusLabel(item.status),
                                          color: _statusColor(item.status),
                                          icon: _statusIcon(item.status),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'Criada por ${item.createdBy} • Empresa ${item.companyId}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: AppColors.steel,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(right: 18),
                              child: Icon(
                                Icons.chevron_right_rounded,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) =>
                  const Center(child: Text('Falha ao carregar coletas')),
            ),
          ),
        ),
      ],
    );
  }

  String _statusLabel(CollectionStatus status) {
    switch (status) {
      case CollectionStatus.open:
        return 'Aberta';
      case CollectionStatus.closed:
        return 'Fechada';
      case CollectionStatus.syncing:
        return 'Sincronizando';
    }
  }

  Color _statusColor(CollectionStatus status) {
    switch (status) {
      case CollectionStatus.open:
        return AppColors.signalTeal;
      case CollectionStatus.closed:
        return AppColors.safeGreen;
      case CollectionStatus.syncing:
        return AppColors.alertAmber;
    }
  }

  IconData _statusIcon(CollectionStatus status) {
    switch (status) {
      case CollectionStatus.open:
        return Icons.play_circle_outline;
      case CollectionStatus.closed:
        return Icons.check_circle_outline;
      case CollectionStatus.syncing:
        return Icons.sync;
    }
  }
}
