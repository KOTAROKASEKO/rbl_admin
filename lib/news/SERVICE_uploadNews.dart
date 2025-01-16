import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rbl_admin/news/MODEL_News.dart';

class NewsService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<void> uploadNews(
    NewsModel news,
  ) async {
    try {
      await firestore.collection('news').doc('news${news.newsNumber}').set(news.toJson());
    } catch (e) {
      print('Error uploading news: $e');
    }
  }
}
