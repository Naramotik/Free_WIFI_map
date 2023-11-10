package com.example.demo.service;

import com.example.demo.dto.CommentToPost;
import com.example.demo.model.Client;
import com.example.demo.model.Comment;
import com.example.demo.model.Mark;
import com.example.demo.repository.ClientRepository;
import com.example.demo.repository.CommentRepository;
import com.example.demo.repository.MarkRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

@Service
public class CommentService {
    @Autowired
    CommentRepository commentRepository;
    @Autowired
    MarkRepository markRepository;
    @Autowired
    ClientRepository clientRepository;

    public Comment save(CommentToPost commentToPost){
        Optional<Mark> mark = markRepository.findByLatitude(commentToPost.getLatitude());
        Client client = clientRepository.findByEmail(commentToPost.getEmail());
        Comment comment = new Comment(null, commentToPost.getComment(), mark.get(), client);
        return commentRepository.save(comment);
    }
    public List<Comment> findComments(String latitude){
        Optional<Mark> mark = markRepository.findByLatitude(latitude);
        return commentRepository.findByMark(mark.get());
    }
}
