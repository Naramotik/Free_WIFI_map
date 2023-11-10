package com.example.demo.controller;

import com.example.demo.repository.CommentRepository;
import com.example.demo.dto.CommentToPost;
import com.example.demo.repository.MarkRepository;
import com.example.demo.model.Comment;
import com.example.demo.model.Mark;
import com.example.demo.service.CommentService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Optional;

@RestController
@CrossOrigin(origins = "http://localhost:3000")
@RequestMapping("/comment")
public class CommentController {
    @Autowired
    CommentService commentService;

    @PostMapping
    public HttpStatus createComment(@RequestBody CommentToPost commentToPost){
        System.out.println(commentToPost);
        commentService.save(commentToPost);
        return HttpStatus.CREATED;
    }
    @GetMapping("/{latitude}")
    public ResponseEntity<List<Comment>> getComments(@PathVariable("latitude") String latitude){
        return new ResponseEntity<List<Comment>> (commentService.findComments(latitude), HttpStatus.OK);
    }
}
