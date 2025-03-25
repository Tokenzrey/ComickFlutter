import 'package:boilerplate/core/stores/error/error_store.dart';
import 'package:boilerplate/domain/entity/post/post_list.dart';
import 'package:boilerplate/domain/entity/post/post.dart';
import 'package:boilerplate/utils/dio/dio_error_util.dart';
import 'package:mobx/mobx.dart';

import '../../../domain/usecase/post/get_post_usecase.dart';

part 'post_store.g.dart';

// ignore: library_private_types_in_public_api
class PostStore = _PostStore with _$PostStore;

abstract class _PostStore with Store {
  // constructor:---------------------------------------------------------------
  _PostStore(this._getPostUseCase, this.errorStore);

  // use cases:-----------------------------------------------------------------
  final GetPostUseCase _getPostUseCase;

  // stores:--------------------------------------------------------------------
  // store for handling errors
  final ErrorStore errorStore;

  // store variables:-----------------------------------------------------------
  static ObservableFuture<PostList?> emptyPostResponse = ObservableFuture.value(
    null,
  );

  @observable
  ObservableFuture<PostList?> fetchPostsFuture = ObservableFuture<PostList?>(
    emptyPostResponse,
  );

  @observable
  PostList? postList;

  @observable
  bool success = false;

  @computed
  bool get loading => fetchPostsFuture.status == FutureStatus.pending;

  // actions:-------------------------------------------------------------------
  @action
  Future getPosts() async {
    final future = _getPostUseCase.call(params: null);
    fetchPostsFuture = ObservableFuture(future);

    future
        .then((postList) {
          this.postList = postList;
        })
        .catchError((error) {
          errorStore.errorMessage = DioExceptionUtil.handleError(error);
        });
  }

  // Add new post action
  @action
  Future<bool> addPost(String title, String body) async {
    try {
      // In a real app, you would call an API here
      // For now, we'll just add to the local list

      // Create a new post
      final newPost = Post(
        id: DateTime.now().millisecondsSinceEpoch, // Generate a unique ID
        title: title,
        body: body,
      );

      // Add it to the list
      if (postList != null && postList!.posts != null) {
        final updatedPosts = List<Post>.from(postList!.posts!);
        updatedPosts.insert(0, newPost); // Add at the beginning

        // Update the postList
        postList = PostList(posts: updatedPosts);
        return true;
      } else {
        // Initialize the list if it's null
        postList = PostList(posts: [newPost]);
        return true;
      }
    } catch (e) {
      errorStore.errorMessage = e.toString();
      return false;
    }
  }

  // Delete post action
  @action
  Future<bool> deletePost(int index) async {
    try {
      // In a real app, you would call an API here
      // For now, we'll just remove from the local list

      if (postList != null &&
          postList!.posts != null &&
          index >= 0 &&
          index < postList!.posts!.length) {
        final updatedPosts = List<Post>.from(postList!.posts!);
        updatedPosts.removeAt(index);

        // Update the postList
        postList = PostList(posts: updatedPosts);
        return true;
      }
      return false;
    } catch (e) {
      errorStore.errorMessage = e.toString();
      return false;
    }
  }
}
