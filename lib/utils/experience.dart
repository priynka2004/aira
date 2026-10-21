// FILE: utils/experience.dart
// Experience is chosen as a range (e.g. "3-5 Years"). The API stores one number, so we map both ways
// and always show the same range label in Onboarding, Profile and Edit Profile.

/// Ranges shown to the artist (same list everywhere).
const List<String> kExperienceRanges = ['1-3 Years', '3-5 Years', '5-10 Years', '10+ Years'];

/// Number saved to the API for each range (middle of the range, always inside it).
const List<int> kExperienceYears = [2, 4, 7, 10];

/// Range → number for the API.
int experienceYearsFromLabel(String label) {
  final i = kExperienceRanges.indexOf(label);
  return i < 0 ? kExperienceYears.first : kExperienceYears[i];
}

/// Number from the API → the range label shown to the artist.
String experienceLabelFromYears(int years) {
  if (years >= 10) return kExperienceRanges[3];
  if (years >= 5) return kExperienceRanges[2];
  if (years >= 3) return kExperienceRanges[1];
  return kExperienceRanges[0];
}
