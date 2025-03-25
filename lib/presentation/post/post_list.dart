// ignore_for_file: use_build_context_synchronously

import 'package:another_flushbar/flushbar_helper.dart';
import 'package:boilerplate/core/widgets/progress_indicator_widget.dart';
import 'package:boilerplate/di/service_locator.dart';
import 'package:boilerplate/presentation/post/store/post_store.dart';
import 'package:boilerplate/utils/locale/app_localization.dart';
import 'package:boilerplate/core/widgets/custom_popup.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class PostListScreen extends StatefulWidget {
  const PostListScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _PostListScreenState createState() => _PostListScreenState();
}

class _PostListScreenState extends State<PostListScreen> {
  //stores:---------------------------------------------------------------------
  final PostStore _postStore = getIt<PostStore>();

  // Text controllers for adding new posts
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();

  // Loading state for add/delete operations
  bool _isOperationInProgress = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // check to see if already called api
    if (!_postStore.loading) {
      _postStore.getPosts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
      floatingActionButton: _buildAddButton(),
    );
  }

  // FAB for adding new posts
  Widget _buildAddButton() {
    return FloatingActionButton(
      onPressed: _showAddPostDialog,
      child: const Icon(Icons.add),
    );
  }

  // Dialog for adding new posts
  void _showAddPostDialog() {
    // Clear text controllers
    _titleController.clear();
    _bodyController.clear();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context).translate('post_add_title')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(
                      context,
                    ).translate('post_title'),
                    border: const OutlineInputBorder(),
                  ),
                  maxLines: 1,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _bodyController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(
                      context,
                    ).translate('post_body'),
                    border: const OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(AppLocalizations.of(context).translate('cancel')),
            ),
            ElevatedButton(
              onPressed:
                  _isOperationInProgress
                      ? null
                      : () =>
                          _addPost(_titleController.text, _bodyController.text),
              child:
                  _isOperationInProgress
                      ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : Text(AppLocalizations.of(context).translate('add')),
            ),
          ],
        );
      },
    );
  }

  // Add post implementation
  Future<void> _addPost(String title, String body) async {
    // Validate inputs
    if (title.isEmpty || body.isEmpty) {
      CustomPopup.show(
        context,
        message: AppLocalizations.of(context).translate('post_fields_required'),
        type: PopupType.error,
        onDismiss: () {},
      );
      return;
    }

    // Show loading
    setState(() {
      _isOperationInProgress = true;
    });

    // Add post
    final success = await _postStore.addPost(title, body);

    // Hide loading
    setState(() {
      _isOperationInProgress = false;
    });

    if (success) {
      Navigator.of(context).pop(); // Close dialog
      CustomPopup.show(
        context,
        message: AppLocalizations.of(context).translate('post_added_success'),
        type: PopupType.success,
        onDismiss: () {},
      );
    } else {
      CustomPopup.show(
        context,
        message: AppLocalizations.of(context).translate('post_add_error'),
        type: PopupType.error,
        onDismiss: () {},
      );
    }
  }

  // Delete post confirmation dialog
  void _showDeleteConfirmation(int index) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            AppLocalizations.of(context).translate('post_delete_title'),
          ),
          content: Text(
            AppLocalizations.of(context).translate('post_delete_confirmation'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(AppLocalizations.of(context).translate('cancel')),
            ),
            ElevatedButton(
              onPressed:
                  _isOperationInProgress ? null : () => _deletePost(index),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child:
                  _isOperationInProgress
                      ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : Text(AppLocalizations.of(context).translate('delete')),
            ),
          ],
        );
      },
    );
  }

  // Delete post implementation
  Future<void> _deletePost(int index) async {
    // Show loading
    setState(() {
      _isOperationInProgress = true;
    });

    // Delete post
    final success = await _postStore.deletePost(index);

    // Hide loading
    setState(() {
      _isOperationInProgress = false;
    });

    if (success) {
      Navigator.of(context).pop(); // Close dialog
      CustomPopup.show(
        context,
        message: AppLocalizations.of(context).translate('post_deleted_success'),
        type: PopupType.success,
        onDismiss: () {},
      );
    } else {
      Navigator.of(context).pop(); // Close dialog
      CustomPopup.show(
        context,
        message: AppLocalizations.of(context).translate('post_delete_error'),
        type: PopupType.error,
        onDismiss: () {},
      );
    }
  }

  // body methods:--------------------------------------------------------------
  Widget _buildBody() {
    return Stack(
      children: <Widget>[_handleErrorMessage(), _buildMainContent()],
    );
  }

  Widget _buildMainContent() {
    return Observer(
      builder: (context) {
        return _postStore.loading
            ? const CustomProgressIndicatorWidget()
            : _buildListView();
      },
    );
  }

  Widget _buildListView() {
    return _postStore.postList != null && _postStore.postList!.posts!.isNotEmpty
        ? ListView.separated(
          itemCount: _postStore.postList!.posts!.length,
          separatorBuilder: (context, position) {
            return const Divider();
          },
          itemBuilder: (context, position) {
            return _buildListItem(position);
          },
        )
        : Center(
          child: Text(
            AppLocalizations.of(context).translate('home_tv_no_post_found'),
          ),
        );
  }

  Widget _buildListItem(int position) {
    return Dismissible(
      key: Key('post_${_postStore.postList?.posts?[position].id}'),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16.0),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        _showDeleteConfirmation(position);
        return false; // Don't dismiss automatically
      },
      child: ListTile(
        dense: true,
        leading: const Icon(Icons.cloud_circle),
        title: Text(
          '${_postStore.postList?.posts?[position].title}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          softWrap: false,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Text(
          '${_postStore.postList?.posts?[position].body}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          softWrap: false,
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => _showDeleteConfirmation(position),
        ),
      ),
    );
  }

  Widget _handleErrorMessage() {
    return Observer(
      builder: (context) {
        if (_postStore.errorStore.errorMessage.isNotEmpty) {
          return _showErrorMessage(_postStore.errorStore.errorMessage);
        }

        return const SizedBox.shrink();
      },
    );
  }

  // General Methods:-----------------------------------------------------------
  _showErrorMessage(String message) {
    Future.delayed(const Duration(milliseconds: 0), () {
      if (message.isNotEmpty) {
        FlushbarHelper.createError(
          message: message,
          title: AppLocalizations.of(context).translate('home_tv_error'),
          duration: const Duration(seconds: 3),
        ).show(context);
      }
    });

    return const SizedBox.shrink();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }
}
