import 'package:artstation/blocs/blocs.dart';
import 'package:artstation/cubits/cubits.dart';
import 'package:artstation/repositories/repositories.dart';
import 'package:artstation/screens/profile/bloc/profile_bloc.dart';
import 'package:artstation/screens/profile/widgets/widgets.dart';
import 'package:artstation/screens/screens.dart';
import 'package:artstation/widgets/widgets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProfileScreenArgs {
  final String userId;

  const ProfileScreenArgs({@required this.userId});
}

class ProfileScreen extends StatefulWidget {
  static const String routeName = '/profile';

  @override
  _ProfileScreenState createState() => _ProfileScreenState();

  static Route route({@required ProfileScreenArgs args}) {
    return MaterialPageRoute(
      settings: const RouteSettings(name: routeName),
      builder: (context) => BlocProvider<ProfileBloc>(
        create: (_) => ProfileBloc(
          userRepository: context.read<UserRepository>(),
          postRepository: context.read<PostRepository>(),
          authBloc: context.read<AuthBloc>(),
          likedPostsCubit: context.read<LikedPostsCubit>(),
        )..add(ProfileLoadUser(userId: args.userId)),
        child: ProfileScreen(),
      ),
    );
  }
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileBloc, ProfileState>(
      listener: (context, state) {
        if (state.status == ProfileStatus.error) {
          showDialog(
            context: context,
            builder: (context) => ErrorDialog(content: state.failure.message),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          body: _buildBody(state),
        );
      },
    );
  }

  Widget _buildBody(ProfileState state) {
    switch (state.status) {
      case ProfileStatus.loading:
        return Center(child: CircularProgressIndicator());
      default:
        return RefreshIndicator(
          onRefresh: () async {
            context
                .read<ProfileBloc>()
                .add(ProfileLoadUser(userId: state.user.id));
            return true;
          },
          child: CustomScrollView(
            slivers: [

              SliverToBoxAdapter(

                child: Column(
                  children: [
                    const SizedBox(height: 50),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24.0, 32.0, 24.0, 0),
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).pushNamed(
                          EditProfileScreen.routeName,
                          arguments: EditProfileScreenArgs(context: context)),
                        child:Row(
                        children: [
                          UserProfileImage(
                            radius: 40.0,
                            profileImageUrl: state.user.profileImageUrl,
                          ),
                          SizedBox(width: 20,),
                          ProfileInfo(
                            username: state.user.username,
                            bio: state.user.bio,
                          ),
                          SizedBox(width: 50,),
                          if (state.isCurrentUser)
                                IconButton(
                                  icon: const Icon(Icons.exit_to_app),
                                  onPressed: () {
                                    context.read<AuthBloc>().add(AuthLogoutRequested());
                                    context.read<LikedPostsCubit>().clearAllLikedPosts();
                                  },
                                ),
                        ],
                      ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30.0,
                        vertical: 10.0,
                      ),
                      child: ProfileStats(
                        isCurrentUser: state.isCurrentUser,
                        isFollowing: state.isFollowing,
                        posts: state.posts.length,
                        followers: state.user.followers,
                        following: state.user.following,
                      ),
                    ),
                  ],
                ),
              ),
              SliverToBoxAdapter(
                child: TabBar(
                  controller: _tabController,
                  labelColor: Theme
                      .of(context)
                      .primaryColor,
                  unselectedLabelColor: Colors.grey,
                  tabs: [
                    Tab(icon: Icon(Icons.list, size: 28.0)),
                    Tab(icon: Icon(Icons.grade_rounded, size: 28.0)),
                  ],
                  indicatorWeight: 3.0,
                  onTap: (i) =>
                      context
                          .read<ProfileBloc>()
                          .add(ProfileToggleGridView(isGridView: i == 1)),
                ),
              ),
              state.isGridView
                  ? SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 2.0,
                  crossAxisSpacing: 2.0,
                ),
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    final post = state.posts[index];
                    return GestureDetector(
                      onTap: () => Navigator.of(context).pushNamed(
                        CommentsScreen.routeName,
                        arguments: CommentsScreenArgs(post: post),
                      ),
                      child: CachedNetworkImage(
                        imageUrl: post.imageUrl,
                        fit: BoxFit.cover,
                      ),
                    );
                  },
                  childCount: state.posts.length,
                ),
              )
                  : SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    final post = state.posts[index];
                    final likedPostsState =
                        context.watch<LikedPostsCubit>().state;
                    final isLiked =
                    likedPostsState.likedPostIds.contains(post.id);
                    return PostView(
                      post: post,
                      isLiked: isLiked,
                      onLike: () {
                        if (isLiked) {
                          context
                              .read<LikedPostsCubit>()
                              .unlikePost(post: post);
                        } else {
                          context
                              .read<LikedPostsCubit>()
                              .likePost(post: post);
                        }
                      },
                    );
                  },
                  childCount: state.posts.length,
                ),
              ),
            ],
          ),
        );
    }
  }
}