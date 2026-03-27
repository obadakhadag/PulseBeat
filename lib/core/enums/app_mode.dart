enum AppMode { online, offline }

AppMode appModeFromStorage(String? value) {
  return AppMode.values.firstWhere(
    (AppMode item) => item.name == value?.trim(),
    orElse: () => AppMode.online,
  );
}
