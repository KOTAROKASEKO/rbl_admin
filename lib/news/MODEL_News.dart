class NewsModel {
  String title;
  String content;
  List<String> imageLinks;
  int newsNumber;

  NewsModel({
    required this.title,
    required this.content,
    required this.imageLinks,
    required this.newsNumber,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      'imageLinks': imageLinks,
      'newsNumber': newsNumber,
    };
  }

  static NewsModel fromJson(Map<String, dynamic> json) {
    return NewsModel(
      title: json['title'],
      content: json['content'],
      imageLinks: List<String>.from(json['imageLinks']),
      newsNumber: json['newsNumber'],
    );
  }
}
