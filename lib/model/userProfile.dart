class UserProfile {
  String? uid;
  String? name;
  String? pfpURL;
  String? email;

  UserProfile({
    required this.uid,
    required this.name,
    required this.pfpURL,
    this.email,
  });

  UserProfile.fromJson(Map<String, dynamic> json) {
    uid = json['uid'];
    name = json['name'];
    pfpURL = json['pfpURL'];
    email = json['email'];

    // Debug print
    print('📦 UserProfile.fromJson: uid=$uid, name=$name, email=$email');
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['pfpURL'] = pfpURL;
    data['uid'] = uid;
    data['email'] = email?.toLowerCase().trim(); // Ensure lowercase

    // Debug print
    print('📤 UserProfile.toJson: $data');

    return data;
  }
}