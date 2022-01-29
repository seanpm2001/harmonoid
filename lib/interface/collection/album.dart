/* 
 *  This file is part of Harmonoid (https://github.com/harmonoid/harmonoid).
 *  
 *  Harmonoid is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *  
 *  Harmonoid is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 *  GNU General Public License for more details.
 *  
 *  You should have received a copy of the GNU General Public License
 *  along with Harmonoid. If not, see <https://www.gnu.org/licenses/>.
 * 
 *  Copyright 2020-2022, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
 */

import 'dart:math';
import 'dart:ui';
import 'dart:async';
import 'package:draggable_scrollbar/draggable_scrollbar.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:provider/provider.dart';
import 'package:animations/animations.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:harmonoid/core/collection.dart';
import 'package:harmonoid/utils/widgets.dart';
import 'package:harmonoid/core/playback.dart';
import 'package:harmonoid/constants/language.dart';
import 'package:harmonoid/utils/dimensions.dart';
import 'package:harmonoid/utils/rendering.dart';

class AlbumTab extends StatelessWidget {
  final controller = ScrollController();
  AlbumTab({
    Key? key,
  }) : super(key: key);

  Widget build(BuildContext context) {
    final elementsPerRow = (MediaQuery.of(context).size.width - tileMargin) ~/
        (kAlbumTileWidth + tileMargin);
    final double width = isMobile
        ? (MediaQuery.of(context).size.width -
                (elementsPerRow + 1) * tileMargin) /
            elementsPerRow
        : kAlbumTileWidth;
    final double height = isMobile
        ? width * kAlbumTileHeight / kAlbumTileWidth
        : kAlbumTileHeight;

    return Consumer<Collection>(
      builder: (context, collection, _) {
        final data = tileGridListWidgetsWithScrollbarSupport(
          context: context,
          tileHeight: height,
          tileWidth: width,
          elementsPerRow: elementsPerRow,
          subHeader: null,
          leadingSubHeader: null,
          leadingWidget: null,
          widgetCount: collection.albums.length,
          builder: (BuildContext context, int index) => AlbumTile(
            height: height,
            width: width,
            album: collection.albums[index],
            key: ValueKey(collection.albums[index]),
          ),
        );
        return isDesktop
            ? collection.tracks.isNotEmpty
                ? CustomListView(
                    padding: EdgeInsets.only(
                      top: tileMargin,
                    ),
                    children: data.widgets,
                  )
                : Center(
                    child: ExceptionWidget(
                      height: 284.0,
                      width: 420.0,
                      margin: EdgeInsets.zero,
                      title: language.NO_COLLECTION_TITLE,
                      subtitle: language.NO_COLLECTION_SUBTITLE,
                    ),
                  )
            : Consumer<Collection>(
                builder: (context, collection, _) => collection
                        .tracks.isNotEmpty
                    ? DraggableScrollbar.semicircle(
                        heightScrollThumb: 56.0,
                        labelConstraints: BoxConstraints.tightFor(
                          width: 120.0,
                          height: 32.0,
                        ),
                        labelTextBuilder: (offset) {
                          final index = (offset -
                                  (kMobileSearchBarHeight +
                                      2 * tileMargin +
                                      MediaQuery.of(context).padding.top)) ~/
                              (height + tileMargin);
                          final album = data
                              .data[index.clamp(
                            0,
                            data.data.length - 1,
                          )]
                              .first as Album;
                          switch (collection.collectionSortType) {
                            case CollectionSort.aToZ:
                              {
                                return Text(
                                  album.albumName![0].toUpperCase(),
                                  style: Theme.of(context).textTheme.headline1,
                                );
                              }
                            case CollectionSort.dateAdded:
                              {
                                return Text(
                                  '${DateTime.fromMillisecondsSinceEpoch(album.timeAdded).label}',
                                  style: Theme.of(context).textTheme.headline4,
                                );
                              }
                            case CollectionSort.year:
                              {
                                return Text(
                                  '${album.year ?? 'Unknown Year'}',
                                  style: Theme.of(context).textTheme.headline4,
                                );
                              }
                            default:
                              return Text(
                                '',
                                style: Theme.of(context).textTheme.headline4,
                              );
                          }
                        },
                        backgroundColor: Theme.of(context).cardColor,
                        controller: controller,
                        child: ListView(
                          controller: controller,
                          itemExtent: height + tileMargin,
                          padding: EdgeInsets.only(
                            top: MediaQuery.of(context).padding.top +
                                kMobileSearchBarHeight +
                                2 * tileMargin,
                          ),
                          children: data.widgets,
                        ),
                      )
                    : Center(
                        child: ExceptionWidget(
                          height: 256.0,
                          width: 420.0,
                          margin: EdgeInsets.zero,
                          title: language.NO_COLLECTION_TITLE,
                          subtitle: language.NO_COLLECTION_SUBTITLE,
                        ),
                      ),
              );
      },
    );
  }
}

class AlbumTile extends StatelessWidget {
  final double height;
  final double width;
  final Album album;

  const AlbumTile({
    Key? key,
    required this.album,
    required this.height,
    required this.width,
  }) : super(key: key);

  Widget build(BuildContext context) {
    Iterable<Color>? palette;

    return isDesktop
        ? Card(
            clipBehavior: Clip.antiAlias,
            elevation: 4.0,
            margin: EdgeInsets.zero,
            child: InkWell(
              onTap: () {
                Navigator.of(context).push(
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        FadeThroughTransition(
                      fillColor: Colors.transparent,
                      animation: animation,
                      secondaryAnimation: secondaryAnimation,
                      child: AlbumScreen(
                        album: this.album,
                      ),
                    ),
                    transitionDuration: Duration(milliseconds: 300),
                    reverseTransitionDuration: Duration(milliseconds: 300),
                  ),
                );
              },
              child: Container(
                height: this.height,
                width: this.width,
                child: Column(
                  children: [
                    ClipRect(
                      child: ScaleOnHover(
                        child: Hero(
                          tag:
                              'album_art_${this.album.albumName}_${this.album.albumArtistName}',
                          child: Image.file(
                            this.album.albumArt,
                            fit: BoxFit.cover,
                            height: this.width,
                            width: this.width,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.0,
                        ),
                        width: this.width,
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              this.album.albumName!.overflow,
                              style: Theme.of(context).textTheme.headline2,
                              textAlign: TextAlign.left,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Padding(
                              padding: EdgeInsets.only(top: 2),
                              child: Text(
                                '${this.album.albumArtistName} ${this.album.year != null ? ' • ' : ''} ${this.album.year ?? ''}',
                                style: isDesktop
                                    ? Theme.of(context)
                                        .textTheme
                                        .headline3
                                        ?.copyWith(
                                          fontSize: 12.0,
                                        )
                                    : Theme.of(context).textTheme.headline3,
                                maxLines: 1,
                                textAlign: TextAlign.left,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        : OpenContainer(
            closedElevation: 4.0,
            closedColor: Theme.of(context).cardColor,
            openElevation: 0.0,
            openColor: Theme.of(context).scaffoldBackgroundColor,
            closedBuilder: (context, open) => InkWell(
              onTap: () async {
                if (palette == null) {
                  final result = await PaletteGenerator.fromImageProvider(
                      FileImage(this.album.albumArt));
                  palette = result.colors;
                }
                open();
              },
              child: Container(
                height: this.height,
                width: this.width,
                child: Column(
                  children: [
                    Ink.image(
                      image: FileImage(this.album.albumArt),
                      fit: BoxFit.cover,
                      height: this.width,
                      width: this.width,
                    ),
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.0,
                        ),
                        width: this.width,
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              this.album.albumName!.overflow,
                              style: Theme.of(context).textTheme.headline2,
                              textAlign: TextAlign.left,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Padding(
                              padding: EdgeInsets.only(top: 2),
                              child: Text(
                                '${this.album.albumArtistName} ${this.album.year != null ? ' • ' : ''} ${this.album.year ?? ''}',
                                style: isDesktop
                                    ? Theme.of(context)
                                        .textTheme
                                        .headline3
                                        ?.copyWith(
                                          fontSize: 12.0,
                                        )
                                    : Theme.of(context).textTheme.headline3,
                                maxLines: 1,
                                textAlign: TextAlign.left,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            openBuilder: (context, _) => AlbumScreen(
              album: album,
              palette: palette,
            ),
          );
  }
}

class AlbumScreen extends StatefulWidget {
  final Album album;
  final Iterable<Color>? palette;
  const AlbumScreen({
    Key? key,
    required this.album,
    this.palette,
  }) : super(key: key);
  AlbumScreenState createState() => AlbumScreenState();
}

class AlbumScreenState extends State<AlbumScreen>
    with SingleTickerProviderStateMixin {
  Color? color;
  Color? secondary;
  Track? hovered;
  bool reactToSecondaryPress = false;
  bool detailsVisible = false;
  bool detailsLoaded = false;
  ScrollController controller = ScrollController(initialScrollOffset: 136.0);

  @override
  void initState() {
    super.initState();
    widget.album.tracks.sort((first, second) =>
        (first.trackNumber ?? 0).compareTo(second.trackNumber ?? 0));
    if (isDesktop) {
      Timer(
        Duration(milliseconds: 300),
        () {
          if (widget.palette == null) {
            PaletteGenerator.fromImageProvider(FileImage(widget.album.albumArt))
                .then((palette) {
              this.setState(() {
                this.color = palette.colors.first;
                this.secondary = palette.colors.last;
                this.detailsVisible = true;
              });
            });
          } else {
            this.setState(() {
              this.detailsVisible = true;
            });
          }
        },
      );
    }
    if (isMobile) {
      Timer(Duration(milliseconds: 100), () {
        this
            .controller
            .animateTo(
              0.0,
              duration: Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            )
            .then((_) {
          Timer(Duration(milliseconds: 50), () {
            this.setState(() {
              this.detailsLoaded = true;
            });
          });
        });
      });
      if (widget.palette != null) {
        this.color = widget.palette?.first;
        this.secondary = widget.palette?.last;
      }
      this.controller.addListener(() {
        if (this.controller.offset == 0.0) {
          this.setState(() {
            this.detailsVisible = true;
          });
        } else if (this.detailsVisible) {
          this.setState(() {
            this.detailsVisible = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return isDesktop
        ? Scaffold(
            body: Container(
              height: MediaQuery.of(context).size.height,
              child: Stack(
                children: [
                  TweenAnimationBuilder(
                    tween: ColorTween(
                      begin: Theme.of(context).appBarTheme.backgroundColor,
                      end: this.color == null
                          ? Theme.of(context).appBarTheme.backgroundColor
                          : this.color!,
                    ),
                    curve: Curves.easeOut,
                    duration: Duration(
                      milliseconds: 200,
                    ),
                    builder: (context, color, _) => DesktopAppBar(
                      height: MediaQuery.of(context).size.height / 3,
                      elevation: 4.0,
                      color: color as Color? ?? Colors.transparent,
                    ),
                  ),
                  Container(
                    height: MediaQuery.of(context).size.height -
                        kDesktopNowPlayingBarHeight,
                    width: MediaQuery.of(context).size.width,
                    child: Container(
                      alignment: Alignment.center,
                      child: Card(
                        clipBehavior: Clip.antiAlias,
                        margin: EdgeInsets.only(top: 72.0),
                        elevation: 4.0,
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth: 1280.0,
                            maxHeight: 720.0,
                          ),
                          width: MediaQuery.of(context).size.width - 136.0,
                          height: MediaQuery.of(context).size.height - 192.0,
                          child: Row(
                            mainAxisSize: MainAxisSize.max,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                flex: 6,
                                child: Hero(
                                  tag:
                                      'album_art_${widget.album.albumName}_${widget.album.albumArtistName}',
                                  child: Stack(
                                    alignment: Alignment.bottomLeft,
                                    children: [
                                      Positioned.fill(
                                        child: Image.file(
                                          widget.album.albumArt,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: ClipOval(
                                          child: Container(
                                            height: 36.0,
                                            width: 36.0,
                                            color: Colors.black54,
                                            child: Material(
                                              color: Colors.transparent,
                                              child: IconButton(
                                                onPressed: () {
                                                  launch(
                                                      'file:///${widget.album.albumArt.path}');
                                                },
                                                icon: Icon(
                                                  Icons.image,
                                                  size: 20.0,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 7,
                                child: CustomListView(
                                  children: [
                                    Stack(
                                      alignment: Alignment.bottomRight,
                                      children: [
                                        Container(
                                          height: 156.0,
                                          padding: EdgeInsets.all(16.0),
                                          alignment: Alignment.centerLeft,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                widget.album.albumName!,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .headline1
                                                    ?.copyWith(fontSize: 24.0),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              SizedBox(height: 8.0),
                                              Text(
                                                '${language.ARTIST}: ${widget.album.albumArtistName}\n${language.YEAR}: ${widget.album.year ?? 'Unknown Year'}\n${language.TRACK}: ${widget.album.tracks.length}',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .headline3,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.all(12.0),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            children: [
                                              FloatingActionButton(
                                                heroTag: 'play_now',
                                                onPressed: () {
                                                  Playback.play(
                                                    index: 0,
                                                    tracks: widget
                                                            .album.tracks +
                                                        ([...collection.tracks]
                                                          ..shuffle()),
                                                  );
                                                },
                                                mini: true,
                                                child: Icon(
                                                  Icons.play_arrow,
                                                ),
                                                tooltip: language.PLAY_NOW,
                                              ),
                                              SizedBox(
                                                width: 8.0,
                                              ),
                                              FloatingActionButton(
                                                heroTag: 'add_to_now_playing',
                                                onPressed: () {
                                                  Playback.add(
                                                    widget.album.tracks,
                                                  );
                                                },
                                                mini: true,
                                                child: Icon(
                                                  Icons.queue_music,
                                                ),
                                                tooltip:
                                                    language.ADD_TO_NOW_PLAYING,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    Divider(
                                      height: 1.0,
                                    ),
                                    LayoutBuilder(
                                      builder: (context, constraints) => Column(
                                        children: [
                                              Row(
                                                children: [
                                                  Container(
                                                    width: 64.0,
                                                    height: 56.0,
                                                    alignment: Alignment.center,
                                                    child: Text(
                                                      '#',
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .headline2,
                                                    ),
                                                  ),
                                                  Expanded(
                                                    child: Container(
                                                      height: 56.0,
                                                      padding: EdgeInsets.only(
                                                          right: 8.0),
                                                      alignment:
                                                          Alignment.centerLeft,
                                                      child: Text(
                                                        language.TRACK,
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .headline2,
                                                      ),
                                                    ),
                                                  ),
                                                  Expanded(
                                                    child: Container(
                                                      height: 56.0,
                                                      padding: EdgeInsets.only(
                                                          right: 8.0),
                                                      alignment:
                                                          Alignment.centerLeft,
                                                      child: Text(
                                                        language.ARTIST,
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .headline2,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Divider(height: 1.0),
                                            ] +
                                            (widget.album.tracks
                                                  ..sort((first, second) =>
                                                      (first.trackNumber ?? 1)
                                                          .compareTo((second
                                                                  .trackNumber ??
                                                              1))))
                                                .map(
                                                  (track) => MouseRegion(
                                                    onEnter: (e) {
                                                      this.setState(() {
                                                        hovered = track;
                                                      });
                                                    },
                                                    onExit: (e) {
                                                      this.setState(() {
                                                        hovered = null;
                                                      });
                                                    },
                                                    child: Listener(
                                                      onPointerDown: (e) {
                                                        reactToSecondaryPress = e
                                                                    .kind ==
                                                                PointerDeviceKind
                                                                    .mouse &&
                                                            e.buttons ==
                                                                kSecondaryMouseButton;
                                                      },
                                                      onPointerUp: (e) async {
                                                        if (!reactToSecondaryPress)
                                                          return;
                                                        var result =
                                                            await showMenu(
                                                          elevation: 4.0,
                                                          context: context,
                                                          position: RelativeRect
                                                              .fromRect(
                                                            Offset(
                                                                    e.position
                                                                        .dx,
                                                                    e.position
                                                                        .dy) &
                                                                Size(228.0,
                                                                    320.0),
                                                            Rect.fromLTWH(
                                                              0,
                                                              0,
                                                              MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .width,
                                                              MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .height,
                                                            ),
                                                          ),
                                                          items:
                                                              trackPopupMenuItems(
                                                            context,
                                                          ),
                                                        );
                                                        await trackPopupMenuHandle(
                                                          context,
                                                          track,
                                                          result,
                                                          recursivelyPopNavigatorOnDeleteIf:
                                                              () => widget
                                                                  .album
                                                                  .tracks
                                                                  .isEmpty,
                                                        );
                                                      },
                                                      child: Material(
                                                        color:
                                                            Colors.transparent,
                                                        child: InkWell(
                                                          onTap: () {
                                                            Playback.play(
                                                              index: widget
                                                                  .album.tracks
                                                                  .indexOf(
                                                                      track),
                                                              tracks: widget
                                                                      .album
                                                                      .tracks +
                                                                  ([
                                                                    ...collection
                                                                        .tracks
                                                                  ]..shuffle()),
                                                            );
                                                          },
                                                          child: Row(
                                                            children: [
                                                              Container(
                                                                width: 64.0,
                                                                height: 48.0,
                                                                padding: EdgeInsets
                                                                    .only(
                                                                        right:
                                                                            8.0),
                                                                alignment:
                                                                    Alignment
                                                                        .center,
                                                                child: hovered ==
                                                                        track
                                                                    ? IconButton(
                                                                        onPressed:
                                                                            () {
                                                                          Playback
                                                                              .play(
                                                                            index:
                                                                                widget.album.tracks.indexOf(track),
                                                                            tracks:
                                                                                widget.album.tracks,
                                                                          );
                                                                        },
                                                                        icon: Icon(
                                                                            Icons.play_arrow),
                                                                        splashRadius:
                                                                            20.0,
                                                                      )
                                                                    : Text(
                                                                        '${track.trackNumber ?? 1}',
                                                                        style: Theme.of(context)
                                                                            .textTheme
                                                                            .headline4,
                                                                      ),
                                                              ),
                                                              Expanded(
                                                                child:
                                                                    Container(
                                                                  height: 48.0,
                                                                  padding: EdgeInsets
                                                                      .only(
                                                                          right:
                                                                              8.0),
                                                                  alignment:
                                                                      Alignment
                                                                          .centerLeft,
                                                                  child: Text(
                                                                    track
                                                                        .trackName!,
                                                                    style: Theme.of(
                                                                            context)
                                                                        .textTheme
                                                                        .headline4,
                                                                    overflow:
                                                                        TextOverflow
                                                                            .ellipsis,
                                                                  ),
                                                                ),
                                                              ),
                                                              Expanded(
                                                                child:
                                                                    Container(
                                                                  height: 48.0,
                                                                  padding: EdgeInsets
                                                                      .only(
                                                                          right:
                                                                              8.0),
                                                                  alignment:
                                                                      Alignment
                                                                          .centerLeft,
                                                                  child: Text(
                                                                    track.trackArtistNames
                                                                            ?.join(', ') ??
                                                                        'Unknown Artist',
                                                                    style: Theme.of(
                                                                            context)
                                                                        .textTheme
                                                                        .headline4,
                                                                    overflow:
                                                                        TextOverflow
                                                                            .ellipsis,
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                )
                                                .toList(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        : Scaffold(
            body: Stack(
              children: [
                CustomScrollView(
                  controller: this.controller,
                  slivers: [
                    SliverAppBar(
                      expandedHeight: MediaQuery.of(context).size.width +
                          136.0 -
                          MediaQuery.of(context).padding.top,
                      pinned: true,
                      leading: IconButton(
                        onPressed: Navigator.of(context).maybePop,
                        icon: Icon(
                          Icons.arrow_back,
                        ),
                        iconSize: 24.0,
                        splashRadius: 20.0,
                      ),
                      forceElevated: true,
                      actions: [
                        // IconButton(
                        //   onPressed: () {},
                        //   icon: Icon(
                        //     Icons.favorite,
                        //   ),
                        //   iconSize: 24.0,
                        //   splashRadius: 20.0,
                        // ),
                        IconButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (subContext) => AlertDialog(
                                title: Text(
                                  language
                                      .COLLECTION_ALBUM_DELETE_DIALOG_HEADER,
                                  style:
                                      Theme.of(subContext).textTheme.headline1,
                                ),
                                content: Text(
                                  language.COLLECTION_ALBUM_DELETE_DIALOG_BODY
                                      .replaceAll(
                                    'NAME',
                                    widget.album.albumName!,
                                  ),
                                  style:
                                      Theme.of(subContext).textTheme.headline3,
                                ),
                                actions: [
                                  MaterialButton(
                                    textColor: Theme.of(context).primaryColor,
                                    onPressed: () async {
                                      await collection.delete(widget.album);
                                      Navigator.of(subContext).pop();
                                    },
                                    child: Text(language.YES),
                                  ),
                                  MaterialButton(
                                    textColor: Theme.of(context).primaryColor,
                                    onPressed: Navigator.of(subContext).pop,
                                    child: Text(language.NO),
                                  ),
                                ],
                              ),
                            );
                          },
                          icon: Icon(
                            Icons.delete,
                          ),
                          iconSize: 24.0,
                          splashRadius: 20.0,
                        ),
                      ],
                      title: TweenAnimationBuilder<double>(
                        tween: Tween<double>(
                          begin: 1.0,
                          end: detailsVisible ? 0.0 : 1.0,
                        ),
                        duration: Duration(milliseconds: 200),
                        builder: (context, value, _) => Opacity(
                          opacity: value,
                          child: Text(
                            language.ALBUM_SINGLE,
                            style: Theme.of(context)
                                .textTheme
                                .headline1
                                ?.copyWith(color: Colors.white),
                          ),
                        ),
                      ),
                      backgroundColor: this.color,
                      flexibleSpace: FlexibleSpaceBar(
                        background: Column(
                          children: [
                            Image.file(
                              widget.album.albumArt,
                              fit: BoxFit.cover,
                              width: MediaQuery.of(context).size.width,
                              height: MediaQuery.of(context).size.width,
                            ),
                            TweenAnimationBuilder<double>(
                              tween: Tween<double>(
                                begin: 1.0,
                                end: detailsVisible ? 1.0 : 0.0,
                              ),
                              duration: Duration(milliseconds: 200),
                              builder: (context, value, _) => Opacity(
                                opacity: value,
                                child: Container(
                                  color: this.color,
                                  height: 136.0,
                                  width: MediaQuery.of(context).size.width,
                                  padding: EdgeInsets.all(16.0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.max,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.album.albumName!.overflow,
                                        style: Theme.of(context)
                                            .textTheme
                                            .headline1
                                            ?.copyWith(
                                              color: [
                                                Colors.white,
                                                Colors.black
                                              ][(this.color?.computeLuminance() ??
                                                          0.0) >
                                                      0.5
                                                  ? 1
                                                  : 0],
                                              fontSize: 24.0,
                                            ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4.0),
                                      Text(
                                        widget.album.albumArtistName!.overflow,
                                        style: Theme.of(context)
                                            .textTheme
                                            .headline1
                                            ?.copyWith(
                                              color: [
                                                Color(0xFFD9D9D9),
                                                Color(0xFF363636)
                                              ][(this.color?.computeLuminance() ??
                                                          0.0) >
                                                      0.5
                                                  ? 1
                                                  : 0],
                                              fontSize: 16.0,
                                            ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2.0),
                                      Text(
                                        '${widget.album.year ?? 'Unknown Year'}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .headline1
                                            ?.copyWith(
                                              color: [
                                                Color(0xFFD9D9D9),
                                                Color(0xFF363636)
                                              ][(this.color?.computeLuminance() ??
                                                          0.0) >
                                                      0.5
                                                  ? 1
                                                  : 0],
                                              fontSize: 16.0,
                                            ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: EdgeInsets.only(
                        top: 12.0,
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) => Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => Playback.play(
                              index: i,
                              tracks: widget.album.tracks +
                                  ([...collection.tracks]..shuffle()),
                            ),
                            onLongPress: () async {
                              var result;
                              await showModalBottomSheet(
                                context: context,
                                builder: (context) => Container(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: trackPopupMenuItems(context)
                                        .map(
                                          (item) => PopupMenuItem(
                                            child: item.child,
                                            onTap: () => result = item.value,
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ),
                              );
                              await trackPopupMenuHandle(
                                context,
                                widget.album.tracks[i],
                                result,
                                recursivelyPopNavigatorOnDeleteIf: () =>
                                    widget.album.tracks.isEmpty,
                              );
                            },
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  height: 64.0,
                                  alignment: Alignment.center,
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 4.0),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      const SizedBox(width: 12.0),
                                      Container(
                                        height: 56.0,
                                        width: 56.0,
                                        alignment: Alignment.center,
                                        child: Text(
                                          '${widget.album.tracks[i].trackNumber ?? 1}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .headline3
                                              ?.copyWith(fontSize: 18.0),
                                        ),
                                      ),
                                      const SizedBox(width: 12.0),
                                      Expanded(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.max,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              widget.album.tracks[i].trackName!
                                                  .overflow,
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .headline2,
                                            ),
                                            const SizedBox(
                                              height: 2.0,
                                            ),
                                            Text(
                                              Duration(
                                                    milliseconds: widget
                                                            .album
                                                            .tracks[i]
                                                            .trackDuration ??
                                                        0,
                                                  ).label +
                                                  ' • ' +
                                                  widget.album.tracks[i]
                                                      .trackArtistNames!
                                                      .take(2)
                                                      .join(', '),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .headline3,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12.0),
                                      Container(
                                        width: 64.0,
                                        height: 64.0,
                                        alignment: Alignment.center,
                                        child: IconButton(
                                          onPressed: () async {
                                            var result;
                                            await showModalBottomSheet(
                                              context: context,
                                              builder: (context) => Container(
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: trackPopupMenuItems(
                                                          context)
                                                      .map(
                                                        (item) => PopupMenuItem(
                                                          child: item.child,
                                                          onTap: () => result =
                                                              item.value,
                                                        ),
                                                      )
                                                      .toList(),
                                                ),
                                              ),
                                            );
                                            await trackPopupMenuHandle(
                                              context,
                                              widget.album.tracks[i],
                                              result,
                                              recursivelyPopNavigatorOnDeleteIf:
                                                  () => widget
                                                      .album.tracks.isEmpty,
                                            );
                                          },
                                          icon: Icon(
                                            Icons.more_vert,
                                          ),
                                          iconSize: 24.0,
                                          splashRadius: 20.0,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Divider(
                                  height: 1.0,
                                  indent: 80.0,
                                ),
                              ],
                            ),
                          ),
                        ),
                        childCount: widget.album.tracks.length,
                      ),
                    ),
                    SliverPadding(
                      padding: EdgeInsets.only(
                        top: 12.0 +
                            (this.detailsLoaded
                                ? 0.0
                                : MediaQuery.of(context).size.height),
                      ),
                    ),
                  ],
                ),
                Positioned(
                  top: MediaQuery.of(context).size.width +
                      MediaQuery.of(context).padding.top -
                      64.0,
                  right: 16.0 + 64.0,
                  child: TweenAnimationBuilder(
                    curve: Curves.easeOut,
                    tween: Tween<double>(
                        begin: 0.0, end: this.detailsVisible ? 1.0 : 0.0),
                    duration: Duration(milliseconds: 200),
                    builder: (context, value, _) => Transform.scale(
                      scale: value as double,
                      child: Transform.rotate(
                        angle: value * pi + pi,
                        child: FloatingActionButton(
                          heroTag: 'play_now',
                          backgroundColor: this.secondary,
                          foregroundColor: [Colors.white, Colors.black][
                              (this.secondary?.computeLuminance() ?? 0.0) > 0.5
                                  ? 1
                                  : 0],
                          child: Icon(Icons.play_arrow),
                          onPressed: () {
                            Playback.play(
                              index: 0,
                              tracks: widget.album.tracks +
                                  ([...collection.tracks]..shuffle()),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: MediaQuery.of(context).size.width +
                      MediaQuery.of(context).padding.top -
                      64.0,
                  right: 16.0,
                  child: TweenAnimationBuilder(
                    curve: Curves.easeOut,
                    tween: Tween<double>(
                        begin: 0.0, end: this.detailsVisible ? 1.0 : 0.0),
                    duration: Duration(milliseconds: 200),
                    builder: (context, value, _) => Transform.scale(
                      scale: value as double,
                      child: Transform.rotate(
                        angle: value * pi + pi,
                        child: FloatingActionButton(
                          heroTag: 'shuffle',
                          backgroundColor: this.secondary,
                          foregroundColor: [Colors.white, Colors.black][
                              (this.secondary?.computeLuminance() ?? 0.0) > 0.5
                                  ? 1
                                  : 0],
                          child: Icon(Icons.shuffle),
                          onPressed: () {
                            Playback.play(
                              index: 0,
                              tracks: [...widget.album.tracks]..shuffle(),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
  }
}

extension on Duration {
  String get label {
    int minutes = inSeconds ~/ 60;
    String seconds = inSeconds - (minutes * 60) > 9
        ? '${inSeconds - (minutes * 60)}'
        : '0${inSeconds - (minutes * 60)}';
    return '$minutes:$seconds';
  }
}