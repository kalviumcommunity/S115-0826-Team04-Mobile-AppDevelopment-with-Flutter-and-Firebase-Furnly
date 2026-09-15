void main() {
  List<int> items = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
  items.sort((a, b) {
    return DateTime.now().compareTo(DateTime.now());
  });
  print("Done");
}
