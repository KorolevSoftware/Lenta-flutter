import 'package:artstation/blocs/blocs.dart';
import 'package:artstation/config/custom_router.dart';
import 'package:artstation/cubits/cubits.dart';
import 'package:artstation/enums/enums.dart';
import 'package:artstation/repositories/repositories.dart';
import 'package:artstation/screens/create_post/cubit/create_post_cubit.dart';
import 'package:artstation/screens/feed/bloc/feed_bloc.dart';
import 'package:artstation/screens/notifications/bloc/notifications_bloc.dart';
import 'package:artstation/screens/profile/bloc/profile_bloc.dart';
import 'package:artstation/screens/screens.dart';
import 'package:artstation/screens/search/cubit/search_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TabNavigator extends StatelessWidget {
  static const String tabNavigatorRoot = '/';

  final GlobalKey<NavigatorState> navigatorKey;
  final BottomNavItem item;

  const TabNavigator({
    Key key,
    @required this.navigatorKey,
    @required this.item,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final routeBuilders = _routeBuilders();
    return Navigator(
      key: navigatorKey,
      initialRoute: tabNavigatorRoot,
      onGenerateInitialRoutes: (_, initialRoute) {
        return [
          MaterialPageRoute(
            settings: RouteSettings(name: tabNavigatorRoot),
            builder: (context) => routeBuilders[initialRoute](context),
          )
        ];
      },
      onGenerateRoute: CustomRouter.onGenerateNestedRoute,
    );
  }

  Map<String, WidgetBuilder> _routeBuilders() {
    return {tabNavigatorRoot: (context) => _getScreen(context, item)};
  }

  Widget _getScreen(BuildContext context, BottomNavItem item) {
    switch (item) {
      case BottomNavItem.feed:
        return BlocProvider<FeedBloc>(
          create: (context) => FeedBloc(
            postRepository: context.read<PostRepository>(),
            authBloc: context.read<AuthBloc>(),
            likedPostsCubit: context.read<LikedPostsCubit>(),
          )..add(FeedFetchPosts()),
          child: FeedScreen(),
        );
      // case BottomNavItem.search:
      //   return BlocProvider<SearchCubit>(
      //     create: (context) =>
      //         SearchCubit(userRepository: context.read<UserRepository>()),
      //     child: SearchScreen(),
      //   );
      case BottomNavItem.create:
        return BlocProvider<CreatePostCubit>(
          create: (context) => CreatePostCubit(
            postRepository: context.read<PostRepository>(),
            storageRepository: context.read<StorageRepository>(),
            authBloc: context.read<AuthBloc>(),
          ),
          child: CreatePostScreen(),
        );
      // case BottomNavItem.notifications:
      //   return BlocProvider<NotificationsBloc>(
      //     create: (context) => NotificationsBloc(
      //       notificationRepository: context.read<NotificationRepository>(),
      //       authBloc: context.read<AuthBloc>(),
      //     ),
      //     child: NotificationsScreen(),
      //   );
      case BottomNavItem.profile:
        return BlocProvider<ProfileBloc>(
          create: (_) => ProfileBloc(
            userRepository: context.read<UserRepository>(),
            postRepository: context.read<PostRepository>(),
            authBloc: context.read<AuthBloc>(),
            likedPostsCubit: context.read<LikedPostsCubit>(),
          )..add(
            ProfileLoadUser(userId: context.read<AuthBloc>().state.user.uid),
          ),
          child: ProfileScreen(),
        );
      default:
        return Scaffold();
    }
  }
}