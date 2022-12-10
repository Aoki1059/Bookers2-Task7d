class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  # 相互フォローのDM機能の記述
  has_many :user_rooms
  has_many :chats
  has_many :rooms, through: :user_rooms
  
  # 閲覧数表示
  has_many :view_counts, dependent: :destroy
  
  # Bookモデルとの1:Nの関係付け
  has_many :books, dependent: :destroy

  # Userモデルとの1:Nの関係付け
  has_many :book_comments, dependent: :destroy

  # Favoriteモデルとの関係付け
  has_many :favorites,dependent: :destroy

  # フォロー機能のアソシエーション(follower_id:自分,followed_id:相手)
  # 自分がフォローしたり、アンフォローするための記述。
  # has_many :中間テーブル名, class_name: "中間テーブルが参照するモデル", foreign_key: "中間テーブルにアクセスする際の入り口", dependent: :destroy
  # @user.relationshipsでユーザーのフォローしている(followed)人を呼び出す
  # Relationshipに格納されているfollwer_idとfollowed_idを呼び出す
  has_many :relationships, class_name: "Relationship", foreign_key: "follower_id", dependent: :destroy

  # 見たいのはuserのフォローしているuser達の情報 ↓
  # relationshipsで、follower_idを指定して、Relationshipを取得(follwer_id=1)
  # followingsで持ってきたRelationshipに対してfollowedを実行
  # followedはfollowed_id = user_idなのでフォローされているユーザーの情報を呼び出す

  # フォロー一覧を表示するための記述
  # has_many :架空のモデル, through: :中間テーブル名, source: :中間テーブルで参照するカラム名（出口）
  has_many :followings, through: :relationships, source: :followed

  # 相手が自分をフォロー、アンフォローするための記述
  has_many :reverse_of_relationships, class_name: "Relationship", foreign_key: "followed_id", dependent: :destroy

  # フォロワー一覧を表示するための
  has_many :followers, through: :reverse_of_relationships, source: :follower

  has_one_attached :profile_image

  validates :name, length: { minimum: 2, maximum: 20 }, uniqueness: true
  validates :introduction, length: {maximum: 50}

  #フォローしたときの処理
  def follow(user_id)
    relationships.create(followed_id: user_id)
  end
  # フォローを外すときの処理
  def unfollow(user_id)
    relationships.find_by(followed_id: user_id).destroy
  end
  # フォローしているかの判定
  def following?(user)
    followings.include?(user)
  end
  # 検索方法の分岐
  # nameはusersテーブルのカラム名
  def self.looks(search, word)
   if search == "perfect_match" #完全一致
     @user = User.where("name LIKE?", "#{word}")
   elsif search == "forward_match" #前方一致
     @user = User.where("name LIKE?","#{word}%")
   elsif search == "backward_match" #後方一致
     @user = User.where("name LIKE?","%#{word}")
   elsif search == "partial_match" #部分一致
     @user = User.where("name LIKE?","%#{word}%")
   else
     @user = User.all
   end
  end


  def get_profile_image
    (profile_image.attached?) ? profile_image : 'no_image.jpg'
  end
end
