'use strict';
const categories = ['Plumbing','Electrical','Painting','Carpentry','Masonry','Gardening','Cleaning','Mechanic'];
function level(points) {
  if (points >= 120) return {level:'Gold', fee:5, visibility:2};
  if (points >= 50) return {level:'Silver', fee:8, visibility:1};
  return {level:'Bronze', fee:10, visibility:0};
}
function reward({stars, onTime, quick, verified}) {
  return 10 + (stars >= 4 ? 5 : 0) + (onTime ? 4 : 0) + (quick ? 3 : 0) + (verified ? 3 : 0);
}
function transition(status, action, isOwner, isAssigned) {
  if (status === 'open' && action === 'accept' && isOwner) return 'booked';
  if (status === 'booked' && action === 'start' && isAssigned) return 'in progress';
  if (status === 'in progress' && action === 'finish' && isAssigned) return 'awaiting review';
  if (status === 'awaiting review' && action === 'review' && isOwner) return 'completed';
  throw Error('This action is unavailable for this job.');
}
module.exports = {categories, level, reward, transition};
