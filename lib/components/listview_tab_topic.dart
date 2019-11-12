// 话题列表页

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/generated/i18n.dart';
import 'package:flutter_app/models/web/item_tab_topic.dart';
import 'package:flutter_app/network/dio_web.dart';
import 'package:flutter_app/pages/page_profile.dart';
import 'package:flutter_app/pages/page_topic_detail.dart';
import 'package:flutter_app/utils/utils.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:ovprogresshud/progresshud.dart';
import 'package:shimmer/shimmer.dart';

import 'circle_avatar.dart';

class TopicListView extends StatefulWidget {
  final String tabKey;

  TopicListView(this.tabKey);

  @override
  State<StatefulWidget> createState() => new TopicListViewState();
}

class TopicListViewState extends State<TopicListView> with AutomaticKeepAliveClientMixin {
  Future<List<TabTopicItem>> topicListFuture;

  ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // 获取数据
    topicListFuture = getTopics();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
        HapticFeedback.heavyImpact(); // 震动反馈（暗示已经滑到底部了）
      }
    });
  }

  Future<List<TabTopicItem>> getTopics() async {
    return await DioWeb.getTopicsByTabKey(widget.tabKey, 0);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return new FutureBuilder<List<TabTopicItem>>(
        future: topicListFuture,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return RefreshIndicator(
                child: snapshot.data.length > 0
                    ? ListView.builder(
                        // primary: false,  // 这样会导致 iOS 上点击状态栏没办法滑到顶部
                        controller: _scrollController,
                        physics: ClampingScrollPhysics(), // iOS 上默认是 BouncingScrollPhysics，体验和下拉刷新有点冲突
                        itemBuilder: (context, index) => TopicItemView(snapshot.data[index]),
                        itemCount: snapshot.data.length)
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text('暂无数据'),
                        ],
                      ),
                onRefresh: _onRefresh);
          } else if (snapshot.hasError) {
            print("wmllll:${snapshot.error}");
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(S.of(context).oops),
                RaisedButton.icon(
                  onPressed: () {
                    Progresshud.show();
                    _onRefresh().then((_) => Progresshud.dismiss());
                  },
                  icon: Icon(Icons.refresh),
                  label: Text(S.of(context).retry),
                )
              ],
            );
          }
          // By default, show a loading skeleton
          return LoadingList();
        });
  }

  //刷新数据,重新设置future就行了
  Future _onRefresh() async {
    await Future.delayed(Duration(seconds: 1), () {
      setState(() {
        topicListFuture = getTopics();
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    _scrollController.dispose();
  }

  @override
  bool get wantKeepAlive => true;
}

/// topic item view
class TopicItemView extends StatefulWidget {
  final TabTopicItem topic;

  TopicItemView(this.topic);

  @override
  _TopicItemViewState createState() => _TopicItemViewState();
}

class _TopicItemViewState extends State<TopicItemView> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        setState(() {
          widget.topic.readStatus = 'read';
        });

        Navigator.push(
          context,
          new MaterialPageRoute(
              builder: (context) => new TopicDetails(
                    widget.topic.topicId,
                    topicTitle: widget.topic.topicContent,
                    nodeName: widget.topic.nodeName,
                    createdId: widget.topic.memberId,
                    avatar: widget.topic.avatar,
                    replyCount: widget.topic.replyCount,
                  )),
        );
      },
      child: new Container(
        padding: EdgeInsets.only(left: 18.0, right: 18.0, top: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            new Text(
              widget.topic.topicContent,
              // 区分：已读 or 未读
              style: TextStyle(fontSize: 17, color: widget.topic.readStatus == 'read' ? Colors.grey : null),
            ),
            SizedBox(
              height: 10,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        InkWell(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              // 头像
                              CircleAvatarWithPlaceholder(
                                imageUrl: widget.topic.avatar,
                                size: 22,
                              ),
                              SizedBox(
                                width: 6,
                              ),
                              // 用户名
                              Text(
                                widget.topic.memberId,
                                textAlign: TextAlign.left,
                                maxLines: 1,
                                style: new TextStyle(fontSize: 13.0, color: Theme.of(context).unselectedWidgetColor),
                              ),
                            ],
                          ),
                          onTap: () {
                            var largeAvatar = Utils.avatarLarge(widget.topic.avatar);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProfilePage(widget.topic.memberId, largeAvatar),
                              ),
                            );
                          },
                        ),
                        SizedBox(
                          width: 6,
                        ),
                        Container(
                          padding: EdgeInsets.only(top: 1, bottom: 1, left: 4, right: 4),
                          decoration: BoxDecoration(
                            border: Border.all(color: Theme.of(context).dividerColor),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: new Text(
                            widget.topic.nodeName,
                            style: new TextStyle(
                              fontSize: 12.0,
                              color: Theme.of(context).disabledColor,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 6,
                        ),
                        Offstage(
                          offstage: widget.topic.lastReplyTime == '',
                          child: Text(
                            widget.topic.lastReplyTime,
                            style: new TextStyle(color: Theme.of(context).disabledColor, fontSize: 12.0),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  width: 5,
                ),
                Offstage(
                  offstage: widget.topic.replyCount == '',
                  child: Row(
                    children: <Widget>[
                      new Icon(
                        FontAwesomeIcons.comment,
                        size: 14.0,
                        color: Colors.grey,
                      ),
                      new Padding(
                        padding: const EdgeInsets.only(left: 4.0),
                        child: new Text(
                          widget.topic.replyCount,
                          style: new TextStyle(fontSize: 13.0, color: Theme.of(context).unselectedWidgetColor),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(
              height: 15,
            ),
            Divider(
              height: 0,
            ),
          ],
        ),
      ),
    );
  }
}

class LoadingList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 15.0),
          child: Shimmer.fromColors(
            baseColor: Theme.of(context).brightness == Brightness.light ? Colors.grey[300] : Colors.black12,
            highlightColor: Theme.of(context).brightness == Brightness.light ? Colors.grey[100] : Colors.white70,
            child: Column(
              children: [0, 1, 2, 3, 4, 5, 6]
                  .map((_) => Padding(
                        padding: const EdgeInsets.only(bottom: 15.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.all(Radius.circular(4)),
                              child: Container(
                                width: double.infinity,
                                height: 18.0,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(
                              height: 14,
                            ),
                            Row(
                              children: <Widget>[
                                ClipOval(
                                  child: Container(
                                    width: 22.0,
                                    height: 22.0,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(
                                  width: 8,
                                ),
                                ClipRRect(
                                  borderRadius: BorderRadius.all(Radius.circular(4)),
                                  child: Container(
                                    width: 40.0,
                                    height: 14.0,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(
                                  width: 8,
                                ),
                                ClipRRect(
                                  borderRadius: BorderRadius.all(Radius.circular(4)),
                                  child: Container(
                                    width: 40.0,
                                    height: 14.0,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(
                                  width: 8,
                                ),
                                ClipRRect(
                                  borderRadius: BorderRadius.all(Radius.circular(4)),
                                  child: Container(
                                    width: 40.0,
                                    height: 14.0,
                                    color: Colors.white,
                                  ),
                                ),
                                Spacer(),
                                Icon(
                                  FontAwesomeIcons.comment,
                                  size: 16.0,
                                  color: Colors.grey,
                                ),
                                SizedBox(
                                  width: 4,
                                ),
                                ClipRRect(
                                  borderRadius: BorderRadius.all(Radius.circular(4)),
                                  child: Container(
                                    width: 20.0,
                                    height: 14.0,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(
                              height: 8,
                            ),
                            Divider(
                              color: Colors.black,
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          )),
    );
  }
}
