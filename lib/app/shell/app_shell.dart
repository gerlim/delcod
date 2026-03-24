import 'package:barcode_app/app/theme/app_colors.dart';
import 'package:barcode_app/features/auth/application/current_session_provider.dart';
import 'package:barcode_app/features/auth/domain/current_session.dart';
import 'package:barcode_app/features/companies/application/active_company_controller.dart';
import 'package:barcode_app/features/companies/domain/company_access.dart';
import 'package:barcode_app/features/sync/application/sync_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AppShell extends ConsumerWidget {
  const AppShell({
    super.key,
    required this.currentLocation,
    required this.child,
  });

  final String currentLocation;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(currentSessionProvider);
    final syncState = ref.watch(syncControllerProvider);
    final isCompact = MediaQuery.sizeOf(context).width < 1000;
    final destinations = _resolveDestinations(session?.roles ?? const {});
    final selectedIndex = _selectedIndex(destinations);
    final activeCompany = _resolveActiveCompany(session);

    return Scaffold(
      backgroundColor: AppColors.mist,
      bottomNavigationBar: isCompact && destinations.length >= 2
          ? NavigationBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: (index) {
                context.go(destinations[index].location);
              },
              destinations: [
                for (final destination in destinations)
                  NavigationDestination(
                    icon: Icon(destination.icon),
                    selectedIcon: Icon(destination.selectedIcon),
                    label: destination.label,
                  ),
              ],
            )
          : null,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.graphite,
              AppColors.mist,
            ],
            stops: [0.0, 0.36],
          ),
        ),
        child: SafeArea(
          child: Row(
            children: [
              if (!isCompact)
                _ShellRail(
                  destinations: destinations,
                  selectedIndex: selectedIndex,
                  activeCompany: activeCompany,
                ),
              Expanded(
                child: Column(
                  children: [
                    _ShellHeader(
                      activeCompany: activeCompany,
                      onCompanyChanged: (companyId) {
                        ref
                            .read(activeCompanyControllerProvider.notifier)
                            .selectCompany(companyId);
                      },
                      sessionName: session?.nome ?? 'Operador',
                      sessionMatricula: session?.matricula ?? '--',
                      companies: session?.availableCompanies ?? const [],
                      syncState: syncState,
                    ),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          isCompact ? 16 : 0,
                          0,
                          isCompact ? 16 : 24,
                          isCompact ? 16 : 24,
                        ),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: AppColors.paper.withOpacity(0.92),
                            borderRadius: BorderRadius.circular(32),
                            border: Border.all(color: AppColors.border),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x1C0B1217),
                                blurRadius: 40,
                                offset: Offset(0, 18),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(isCompact ? 16 : 24),
                            child: child,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<_ShellDestination> _resolveDestinations(Set<String> roles) {
    final destinations = <_ShellDestination>[
      const _ShellDestination(
        label: 'Coletas',
        location: '/collections',
        icon: Icons.inventory_2_outlined,
        selectedIcon: Icons.inventory_2,
      ),
    ];

    if (_hasAnyRole(roles, const {'manager', 'admin'})) {
      destinations.add(
        const _ShellDestination(
          label: 'Auditoria',
          location: '/audit',
          icon: Icons.history_toggle_off_outlined,
          selectedIcon: Icons.history_toggle_off,
        ),
      );
    }

    if (_hasAnyRole(roles, const {'admin'})) {
      destinations.add(
        const _ShellDestination(
          label: 'Administracao',
          location: '/admin',
          icon: Icons.admin_panel_settings_outlined,
          selectedIcon: Icons.admin_panel_settings,
        ),
      );
    }

    return destinations;
  }

  int _selectedIndex(List<_ShellDestination> destinations) {
    final index = destinations.indexWhere((destination) {
      if (destination.location == '/collections' &&
          currentLocation.startsWith('/collections')) {
        return true;
      }

      return currentLocation == destination.location;
    });

    return index >= 0 ? index : 0;
  }

  CompanyAccess? _resolveActiveCompany(CurrentSession? session) {
    if (session == null) {
      return null;
    }

    for (final company in session.availableCompanies) {
      if (company.companyId == session.activeCompanyId) {
        return company;
      }
    }

    if (session.availableCompanies.isNotEmpty) {
      return session.availableCompanies.first;
    }

    return null;
  }

  bool _hasAnyRole(Set<String> currentRoles, Set<String> expectedRoles) {
    for (final role in expectedRoles) {
      if (currentRoles.contains(role)) {
        return true;
      }
    }

    return false;
  }
}

class _ShellHeader extends StatelessWidget {
  const _ShellHeader({
    required this.activeCompany,
    required this.onCompanyChanged,
    required this.sessionName,
    required this.sessionMatricula,
    required this.companies,
    required this.syncState,
  });

  final CompanyAccess? activeCompany;
  final ValueChanged<String> onCompanyChanged;
  final String sessionName;
  final String sessionMatricula;
  final List<CompanyAccess> companies;
  final SyncState syncState;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 1000;

    return Padding(
      padding: EdgeInsets.fromLTRB(compact ? 16 : 24, 24, 24, 16),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _OperationCard(
                  activeCompany: activeCompany,
                  companies: companies,
                  onCompanyChanged: onCompanyChanged,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _HeaderMetric(
                        label: 'Perfil operacional',
                        value: sessionName,
                        supporting: 'Matricula $sessionMatricula',
                        icon: Icons.verified_user_outlined,
                        color: AppColors.signalTeal,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _HeaderMetric(
                        label: 'Sincronizacao',
                        value: syncState.label,
                        supporting: syncState.pendingCount == 0
                            ? 'Sem pendencias'
                            : '${syncState.pendingCount} pendencias',
                        icon: _syncIcon(syncState.status),
                        color: _syncColor(syncState.status),
                      ),
                    ),
                  ],
                ),
              ],
            )
          : Wrap(
              spacing: 16,
              runSpacing: 16,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _OperationCard(
                  activeCompany: activeCompany,
                  companies: companies,
                  onCompanyChanged: onCompanyChanged,
                ),
                _HeaderMetric(
                  label: 'Perfil operacional',
                  value: sessionName,
                  supporting: 'Matricula $sessionMatricula',
                  icon: Icons.verified_user_outlined,
                  color: AppColors.signalTeal,
                ),
                _HeaderMetric(
                  label: 'Sincronizacao',
                  value: syncState.label,
                  supporting: syncState.pendingCount == 0
                      ? 'Sem pendencias'
                      : '${syncState.pendingCount} pendencias',
                  icon: _syncIcon(syncState.status),
                  color: _syncColor(syncState.status),
                ),
              ],
            ),
    );
  }

  static IconData _syncIcon(SyncStatus status) {
    switch (status) {
      case SyncStatus.offline:
        return Icons.cloud_off_outlined;
      case SyncStatus.syncing:
        return Icons.sync;
      case SyncStatus.synced:
        return Icons.cloud_done_outlined;
      case SyncStatus.failed:
        return Icons.error_outline;
    }
  }

  static Color _syncColor(SyncStatus status) {
    switch (status) {
      case SyncStatus.offline:
        return AppColors.steel;
      case SyncStatus.syncing:
        return AppColors.alertAmber;
      case SyncStatus.synced:
        return AppColors.safeGreen;
      case SyncStatus.failed:
        return AppColors.faultRed;
    }
  }
}

class _HeaderMetric extends StatelessWidget {
  const _HeaderMetric({
    required this.label,
    required this.value,
    required this.supporting,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final String supporting;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.all(10),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 16),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.steel,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            supporting,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.steel,
                ),
          ),
        ],
      ),
    );
  }
}

class _OperationCard extends StatelessWidget {
  const _OperationCard({
    required this.activeCompany,
    required this.companies,
    required this.onCompanyChanged,
  });

  final CompanyAccess? activeCompany;
  final List<CompanyAccess> companies;
  final ValueChanged<String> onCompanyChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 280, maxWidth: 420),
      decoration: BoxDecoration(
        color: AppColors.paper.withOpacity(0.12),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.paper.withOpacity(0.18),
        ),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Operacao ativa',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Colors.white70,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            activeCompany?.companyName ?? 'Selecione a empresa',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: activeCompany?.companyId,
              dropdownColor: AppColors.graphite,
              borderRadius: BorderRadius.circular(18),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white,
                  ),
              items: [
                for (final company in companies)
                  DropdownMenuItem<String>(
                    value: company.companyId,
                    child: Text(company.companyName),
                  ),
              ],
              onChanged: (value) {
                if (value != null) {
                  onCompanyChanged(value);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ShellRail extends StatelessWidget {
  const _ShellRail({
    required this.destinations,
    required this.selectedIndex,
    required this.activeCompany,
  });

  final List<_ShellDestination> destinations;
  final int selectedIndex;
  final CompanyAccess? activeCompany;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      margin: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.graphite,
        borderRadius: BorderRadius.circular(32),
        boxShadow: const [
          BoxShadow(
            color: Color(0x330B1217),
            blurRadius: 32,
            offset: Offset(0, 24),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.qr_code_scanner_rounded,
                  size: 34,
                  color: Colors.white,
                ),
                const SizedBox(height: 18),
                Text(
                  'Barcode App',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  activeCompany?.companyName ?? 'Multiempresa industrial',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white70,
                      ),
                ),
              ],
            ),
          ),
          Expanded(
            child: destinations.length >= 2
                ? NavigationRail(
                    selectedIndex: selectedIndex,
                    extended: true,
                    backgroundColor: Colors.transparent,
                    minExtendedWidth: 240,
                    selectedIconTheme: const IconThemeData(color: Colors.white),
                    unselectedIconTheme:
                        const IconThemeData(color: Colors.white70),
                    selectedLabelTextStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                    unselectedLabelTextStyle: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                    indicatorColor: AppColors.signalTeal,
                    destinations: [
                      for (final destination in destinations)
                        NavigationRailDestination(
                          icon: Icon(destination.icon),
                          selectedIcon: Icon(destination.selectedIcon),
                          label: Text(destination.label),
                        ),
                    ],
                    onDestinationSelected: (index) {
                      context.go(destinations[index].location);
                    },
                  )
                : ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    children: [
                      for (final destination in destinations)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: FilledButton.tonalIcon(
                            onPressed: () => context.go(destination.location),
                            icon: Icon(
                              currentIndexMatches(
                                selectedIndex,
                                destinations.indexOf(destination),
                              )
                                  ? destination.selectedIcon
                                  : destination.icon,
                            ),
                            label: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(destination.label),
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  bool currentIndexMatches(
    int currentIndex,
    int destinationIndex,
  ) {
    return currentIndex == destinationIndex;
  }
}

class _ShellDestination {
  const _ShellDestination({
    required this.label,
    required this.location,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final String location;
  final IconData icon;
  final IconData selectedIcon;
}
