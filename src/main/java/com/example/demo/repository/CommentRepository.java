package com.example.demo.repository;

import com.example.demo.model.Comment;
import com.example.demo.model.Mark;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface CommentRepository extends JpaRepository<Comment, Long> {

    List<Comment> findByMark(Mark mark);
}
