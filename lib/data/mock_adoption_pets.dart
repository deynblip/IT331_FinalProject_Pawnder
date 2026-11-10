import '../models/adoption_pet.dart';

// TEMPORARY DATA. Will be replaced by data from the backend.
final List<AdoptionPet> mockAdoptionPets = [
  const AdoptionPet(
    id: 'a1',
    name: 'Tiwi',
    animalType: 'Cat',
    age: '1 year',
    sex: 'Male',
    location: 'Alangilan, Batangas City',
    posterName: 'Angela May',
    description:
    'Tiwi is a gentle and playful orange cat who loves to be around people. '
        'He is litter trained and gets along well with other cats.',
    healthInfo: 'Vaccinated and dewormed. No known medical issues.',
    photos: ['assets/images/sick_cat.jpg'],
  ),
  const AdoptionPet(
    id: 'a2',
    name: 'Buddy',
    animalType: 'Dog',
    age: '2 years',
    sex: 'Male',
    location: 'Kumintang Ibaba, Batangas City',
    posterName: 'Shanea Mae',
    description:
    'Buddy is a friendly and loyal dog. He is good with kids and loves walks.',
    healthInfo: 'Vaccinated. Dewormed last month.',
    photos: ['assets/images/injured_dog.jpg', 'assets/images/sick_dog.jpg'],
  ),
  const AdoptionPet(
    id: 'a3',
    name: 'Mingming',
    animalType: 'Cat',
    age: '1 year',
    sex: 'Female',
    location: 'Balagtas, Batangas City',
    posterName: 'Maria Santos',
    description: 'Mingming is calm and sweet. She likes quiet homes.',
    healthInfo: 'Spayed. Up to date on vaccines.',
    photos: ['assets/images/injured_cat.jpg'],
  ),
  const AdoptionPet(
    id: 'a4',
    name: 'Brownie',
    animalType: 'Dog',
    age: '3 months',
    sex: 'Male',
    location: 'Batangas City',
    posterName: 'Dane Angela',
    description: 'A friendly and playful puppy looking for a loving home.',
    healthInfo: '',
    photos: ['assets/images/sick_dog.jpg'],
    isMine: true,
  ),
  const AdoptionPet(
    id: 'a5',
    name: 'Mimi',
    animalType: 'Cat',
    age: '4 months',
    sex: 'Female',
    location: 'Alangilan, Batangas City',
    posterName: 'Shanea Mae',
    description: 'Mimi is a curious kitten who loves to explore.',
    healthInfo: 'Dewormed. First vaccine done.',
    photos: ['assets/images/stray_kitten.jpg'],
  ),
];