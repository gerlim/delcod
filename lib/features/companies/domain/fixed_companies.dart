class FixedCompany {
  const FixedCompany({
    required this.code,
    required this.name,
  });

  final String code;
  final String name;
}

const fixedCompanies = <FixedCompany>[
  FixedCompany(
    code: 'del-papeis',
    name: 'Del Papeis',
  ),
  FixedCompany(
    code: 'bora-embalagens',
    name: 'Bora Embalagens',
  ),
  FixedCompany(
    code: 'abn-embalagens',
    name: 'ABN Embalagens',
  ),
];
