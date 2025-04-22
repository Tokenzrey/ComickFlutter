import 'package:boilerplate/presentation/home/components/customappbar.dart';
import 'package:boilerplate/presentation/story_base/model/list_card_model.dart';
import 'package:flutter/material.dart';
import 'widget/story_card.dart';

class StoryBase extends StatefulWidget {
  const StoryBase({super.key});

  @override
  State<StoryBase> createState() => _StoryBaseState();
}

class _StoryBaseState extends State<StoryBase> {
  final List<ListCard> _listCard = [];
  final int _itemsCount = 10;
  final ScrollController _mainScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    List<ListCard> newListCard = List.generate(_itemsCount, (index) {
      return ListCard(
        imageUrl: 'https://meo.comick.pictures/kRX7nW-m.jpg',
        tittle: 'The Archmage\'s Restaurant',
        story:
            'The Archmage\'s Restaurant is a webcomic that follows the adventures of a powerful archmage who opens a restaurant in a fantasy world. The story combines elements of magic, cooking, and humor as the archmage navigates the challenges of running a restaurant while dealing with various magical creatures and situations.',
      );
    });

    setState(() {
      _listCard.addAll(newListCard);
    });
  }

  @override
  void dispose() {
    _mainScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(),
      floatingActionButton: _buildFloatingActionButtons(),
      body: SingleChildScrollView(
          controller: _mainScrollController,
          child: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(
                    'https://static.vecteezy.com/system/resources/previews/053/701/345/non_2x/out-of-focus-plants-at-the-bottom-sides-with-a-pure-white-background-picture-photo.jpg'),
                fit: BoxFit.cover,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: _listCard.length,
                  itemBuilder: (context, index) {
                    return StoryCard(
                      listCard: _listCard[index],
                    );
                  },
                ),
              ],
            ),
          )),
    );
  }

  Widget _buildFloatingActionButtons() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        FloatingActionButton(
          backgroundColor: Colors.purple.shade200,
          onPressed: () => showDialog<String>(
            context: context,
            builder: (BuildContext context) => Dialog(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    const Text('This is a typical dialog.'),
                    const SizedBox(height: 15),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('Create'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          child: Icon(
            Icons.add,
            color: Colors.deepPurple,
          ),
        ),
      ],
    );
  }
}
