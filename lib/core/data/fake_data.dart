import 'package:travel_diary_frontend/auth/data/models/user.dart';
import 'package:travel_diary_frontend/feed/data/models/feed_post.dart';
import 'package:travel_diary_frontend/trips/data/models/media.dart';
import 'package:travel_diary_frontend/trips/data/models/step_post.dart';
import 'package:travel_diary_frontend/trips/data/models/trip.dart';

class FakeData {
  FakeData._();

  // Current user
  static User get currentUser => User(
        id: '1',
        username: 'traveler_john',
        email: 'john@example.com',
        avatarUrl: 'https://i.pravatar.cc/150?img=12',
        createdAt: DateTime.now().subtract(const Duration(days: 365)),
        defaultVisibility: 'FRIENDS',
        bio: '🌍 Travel enthusiast | 📸 Photography lover | ✈️ 25 countries and counting',
        tripsCount: 8,
        stepsCount: 142,
        followersCount: 234,
        followingCount: 189,
      );

  // Other users
  static final List<User> users = [
    User(
      id: '2',
      username: 'adventure_sarah',
      email: 'a',
      avatarUrl: 'https://i.pravatar.cc/150?img=5',
      createdAt: DateTime.now().subtract(const Duration(days: 400)),
      bio: 'Exploring one city at a time 🗺️',
      tripsCount: 12,
      stepsCount: 256,
    ),
    User(
      id: '3',
      username: 'wanderlust_mike',
      email: 'mike@example.com',
      avatarUrl: 'https://i.pravatar.cc/150?img=33',
      createdAt: DateTime.now().subtract(const Duration(days: 300)),
      bio: 'Digital nomad living the dream',
      tripsCount: 15,
      stepsCount: 324,
    ),
    User(
      id: '4',
      username: 'explore_emma',
      email: 'emma@example.com',
      avatarUrl: 'https://i.pravatar.cc/150?img=47',
      createdAt: DateTime.now().subtract(const Duration(days: 200)),
      bio: 'Mountains > Beaches 🏔️',
      tripsCount: 6,
      stepsCount: 89,
    ),
  ];

  // Sample trips for current user
  static final List<Trip> myTrips = [
    Trip(
      id: '1',
      title: 'European Adventure 2024',
      coverUrl: 'https://images.unsplash.com/photo-1502602898657-3e91760cbb34?w=800',
      startDate: DateTime(2024, 6, 1),
      endDate: DateTime(2024, 6, 21),
      visibility: 'PUBLIC',
      stats: const TripStats(
        stepsCount: 28,
        distanceKm: 3245,
        countriesCount: 5,
        citiesCount: 12,
        photosCount: 156,
      ),
      createdBy: '1',
      createdAt: DateTime(2024, 6, 1),
      description: 'An unforgettable journey through Europe\'s most beautiful cities',
    ),
    Trip(
      id: '2',
      title: 'Southeast Asia Backpacking',
      coverUrl: 'https://images.unsplash.com/photo-1552465011-b4e21bf6e79a?w=800',
      startDate: DateTime(2024, 3, 10),
      endDate: DateTime(2024, 4, 15),
      visibility: 'FRIENDS',
      stats: const TripStats(
        stepsCount: 42,
        distanceKm: 4521,
        countriesCount: 4,
        citiesCount: 18,
        photosCount: 234,
      ),
      createdBy: '1',
      createdAt: DateTime(2024, 3, 10),
      description: 'Exploring the vibrant cultures of Southeast Asia',
    ),
    Trip(
      id: '3',
      title: 'Iceland Road Trip',
      coverUrl: 'https://images.unsplash.com/photo-1504893524553-b855bce32c67?w=800',
      startDate: DateTime(2024, 1, 5),
      endDate: DateTime(2024, 1, 12),
      visibility: 'PUBLIC',
      stats: const TripStats(
        stepsCount: 15,
        distanceKm: 1876,
        countriesCount: 1,
        citiesCount: 8,
        photosCount: 98,
      ),
      createdBy: '1',
      createdAt: DateTime(2024, 1, 5),
      description: 'Chasing waterfalls and northern lights',
    ),
    Trip(
      id: '4',
      title: 'New Zealand South Island',
      coverUrl: 'https://images.unsplash.com/photo-1469854523086-cc02fe5d8800?w=800',
      startDate: DateTime(2023, 11, 1),
      endDate: DateTime(2023, 11, 20),
      visibility: 'PUBLIC',
      stats: const TripStats(
        stepsCount: 22,
        distanceKm: 2156,
        countriesCount: 1,
        citiesCount: 10,
        photosCount: 187,
      ),
      createdBy: '1',
      createdAt: DateTime(2023, 11, 1),
      description: 'Lord of the Rings filming locations tour',
    ),
  ];

  // Sample step posts
  static final List<StepPost> sampleSteps = [
    StepPost(
      id: '1',
      tripId: '1',
      title: 'Arrived in Paris!',
      text: 'Finally here! The Eiffel Tower is even more magnificent in person. Can\'t wait to explore the city of lights! 🗼✨',
      location: const LocationData(
        lat: 48.8584,
        lng: 2.2945,
        name: 'Eiffel Tower',
        city: 'Paris',
        country: 'France',
        countryCode: 'FR',
      ),
      takenAt: DateTime(2024, 6, 1, 14, 30),
      photos: [
        const Media(
          id: '1',
          url: 'https://images.unsplash.com/photo-1511739001486-6bfe10ce785f?w=800',
          ratio: 1.5,
          type: 'IMAGE',
          thumbUrl: 'https://images.unsplash.com/photo-1511739001486-6bfe10ce785f?w=400',
        ),
        const Media(
          id: '2',
          url: 'https://images.unsplash.com/photo-1502602898657-3e91760cbb34?w=800',
          ratio: 1.5,
          type: 'IMAGE',
          thumbUrl: 'https://images.unsplash.com/photo-1502602898657-3e91760cbb34?w=400',
        ),
      ],
      visibility: 'PUBLIC',
      likesCount: 45,
      commentsCount: 8,
      createdAt: DateTime(2024, 6, 1, 15, 0),
    ),
    StepPost(
      id: '2',
      tripId: '1',
      title: 'Louvre Museum',
      text: 'Spent the entire day at the Louvre. The Mona Lisa was smaller than I expected but still incredible!',
      location: const LocationData(
        lat: 48.8606,
        lng: 2.3376,
        name: 'Louvre Museum',
        city: 'Paris',
        country: 'France',
        countryCode: 'FR',
      ),
      takenAt: DateTime(2024, 6, 2, 11, 15),
      photos: [
        const Media(
          id: '3',
          url: 'https://images.unsplash.com/photo-1499856871958-5b9627545d1a?w=800',
          ratio: 1.5,
          type: 'IMAGE',
        ),
      ],
      visibility: 'PUBLIC',
      likesCount: 32,
      commentsCount: 5,
      createdAt: DateTime(2024, 6, 2, 18, 30),
    ),
    StepPost(
      id: '3',
      tripId: '1',
      title: 'Venice Canals',
      text: 'Gondola rides at sunset 🚤 This city is pure magic! Every corner looks like a postcard.',
      location: const LocationData(
        lat: 45.4408,
        lng: 12.3155,
        name: 'Grand Canal',
        city: 'Venice',
        country: 'Italy',
        countryCode: 'IT',
      ),
      takenAt: DateTime(2024, 6, 8, 19, 45),
      photos: [
        const Media(
          id: '4',
          url: 'https://images.unsplash.com/photo-1523906834658-6e24ef2386f9?w=800',
          ratio: 1.5,
          type: 'IMAGE',
        ),
        const Media(
          id: '5',
          url: 'https://images.unsplash.com/photo-1534113414509-0eec2bfb493f?w=800',
          ratio: 1.5,
          type: 'IMAGE',
        ),
        const Media(
          id: '6',
          url: 'https://images.unsplash.com/photo-1518361593606-2d1a41fc4ab0?w=800',
          ratio: 1.5,
          type: 'IMAGE',
        ),
      ],
      visibility: 'PUBLIC',
      likesCount: 89,
      commentsCount: 12,
      createdAt: DateTime(2024, 6, 8, 21, 0),
    ),
  ];

  // Sample feed posts
  static final List<FeedPost> feedPosts = [
    FeedPost(
      step: StepPost(
        id: '10',
        tripId: '5',
        title: 'Santorini Sunset',
        text: 'There\'s nothing quite like watching the sunset in Santorini. The white buildings against the blue domes create the perfect backdrop! 🌅',
        location: const LocationData(
          lat: 36.4618,
          lng: 25.3753,
          name: 'Oia',
          city: 'Santorini',
          country: 'Greece',
          countryCode: 'GR',
        ),
        takenAt: DateTime.now().subtract(const Duration(hours: 3)),
        photos: [
          const Media(
            id: '10',
            url: 'https://images.unsplash.com/photo-1613395877344-13d4a8e0d49e?w=800',
            ratio: 1.5,
            type: 'IMAGE',
          ),
        ],
        visibility: 'PUBLIC',
        likesCount: 156,
        commentsCount: 23,
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      ),
      user: const FeedUser(
        id: '2',
        username: 'adventure_sarah',
        avatarUrl: 'https://i.pravatar.cc/150?img=5',
      ),
      tripTitle: 'Greek Islands Adventure',
    ),
    FeedPost(
      step: StepPost(
        id: '11',
        tripId: '6',
        title: 'Tokyo Street Food',
        text: 'The street food scene in Tokyo is absolutely incredible! Just tried the best ramen of my life 🍜',
        location: const LocationData(
          lat: 35.6762,
          lng: 139.6503,
          name: 'Shibuya',
          city: 'Tokyo',
          country: 'Japan',
          countryCode: 'JP',
        ),
        takenAt: DateTime.now().subtract(const Duration(hours: 8)),
        photos: [
          const Media(
            id: '11',
            url: 'https://images.unsplash.com/photo-1542051841857-5f90071e7989?w=800',
            ratio: 1.5,
            type: 'IMAGE',
          ),
          const Media(
            id: '12',
            url: 'https://images.unsplash.com/photo-1554797589-7241bb691973?w=800',
            ratio: 1.5,
            type: 'IMAGE',
          ),
        ],
        visibility: 'PUBLIC',
        likesCount: 98,
        commentsCount: 15,
        createdAt: DateTime.now().subtract(const Duration(hours: 8)),
      ),
      user: const FeedUser(
        id: '3',
        username: 'wanderlust_mike',
        avatarUrl: 'https://i.pravatar.cc/150?img=33',
      ),
      tripTitle: 'Japan Discovery',
    ),
    FeedPost(
      step: StepPost(
        id: '12',
        tripId: '7',
        title: 'Hiking Machu Picchu',
        text: 'Made it to the top! The Inca Trail was challenging but absolutely worth it. The views are breathtaking! 🏔️',
        location: const LocationData(
          lat: -13.1631,
          lng: -72.5450,
          name: 'Machu Picchu',
          city: 'Cusco',
          country: 'Peru',
          countryCode: 'PE',
        ),
        takenAt: DateTime.now().subtract(const Duration(days: 1)),
        photos: [
          const Media(
            id: '13',
            url: 'https://images.unsplash.com/photo-1587595431973-160d0d94add1?w=800',
            ratio: 1.5,
            type: 'IMAGE',
          ),
        ],
        visibility: 'PUBLIC',
        likesCount: 234,
        commentsCount: 42,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      user: const FeedUser(
        id: '4',
        username: 'explore_emma',
        avatarUrl: 'https://i.pravatar.cc/150?img=47',
      ),
      tripTitle: 'Peru Adventure',
    ),
    FeedPost(
      step: sampleSteps[0],
      user: FeedUser(
        id: currentUser.id,
        username: currentUser.username,
        avatarUrl: currentUser.avatarUrl,
      ),
      tripTitle: 'European Adventure 2024',
    ),
    FeedPost(
      step: sampleSteps[2],
      user: FeedUser(
        id: currentUser.id,
        username: currentUser.username,
        avatarUrl: currentUser.avatarUrl,
      ),
      tripTitle: 'European Adventure 2024',
    ),
  ];

  // Helper method to get more feed posts (for pagination)
  static List<FeedPost> getMoreFeedPosts(int page) {
    // In a real app, this would fetch from backend
    // For demo, we'll just return the same posts with different IDs
    return feedPosts;
  }

  // Helper method to get steps for a trip
  static List<StepPost> getStepsForTrip(String tripId) {
    return sampleSteps.where((step) => step.tripId == tripId).toList();
  }
}

